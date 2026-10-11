#!/usr/bin/env python3
"""
Modbus TCP cache + write-through proxy for Huawei SUN2000 inverters.

The SUN2000's Modbus TCP interface (via the SDongle) accepts only a very small
number of concurrent connections. Point Home Assistant, a heating controller and
a dashboard at it at the same time and it starts refusing connections and
dropping reads.

This proxy sits in front of it: it holds exactly ONE connection to the inverter,
polls a configured set of registers on an interval, and serves those cached
values to as many Modbus TCP clients as you like. Write requests (FC6) are
forwarded straight through to the inverter, so control still works.
"""

import argparse
import asyncio
import logging
import os
import signal
import struct
import sys
import time

import yaml

register_cache = {}
cache_lock = asyncio.Lock()
last_update = 0
REGISTER_BATCHES = []
args = {}


def load_config_file(config_path):
    """Attempts to read and parse the configuration file if it exists."""
    if config_path and os.path.exists(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                cfg = yaml.safe_load(f)
                if cfg and isinstance(cfg, dict):
                    return cfg
        except Exception:  # noqa: BLE001,S110
            pass  # Fail silently to allow alternative layers to handle it
    return {}


def load_and_convert(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)

        if not data or "register_batches" not in data:
            logger.error("Error: Key 'register_batches' missing from the file.")
            sys.exit(1)

        register_batches = []
        for item in data["register_batches"]:
            if isinstance(item, list) and len(item) == 2:
                register_batches.append((item[0], item[1]))
        return register_batches

    except FileNotFoundError:
        logger.error(f"Error: The file '{file_path}' was not found.")
        sys.exit(1)
    except yaml.YAMLError as e:
        logger.error(
            f"Error: The file '{file_path}' does not contain valid YAML syntax.\nDetails: {e}"
        )
        sys.exit(1)
    except Exception as e:  # noqa: BLE001
        logger.error(f"An unexpected error occurred: {e}")
        sys.exit(1)


def init_cache():
    """Initialize all register addresses with 0."""
    for start, count in REGISTER_BATCHES:
        for i in range(count):
            register_cache[start + i] = 0


async def reader_loop():
    """Periodically read from SDongle and update cache."""
    global last_update

    # Try rapidly at first to fill cache, then slow down
    retry_delay = 5

    while True:
        success = await read_sdongle()
        if success:
            last_update = time.time()
            retry_delay = args.pooling  # Normal interval after success
        else:
            retry_delay = min(retry_delay, 10)  # Retry faster on failure
            age = time.time() - last_update if last_update > 0 else -1
            if age > 120:
                logger.warning(f"Cache stale for {age:.0f}s")
        await asyncio.sleep(retry_delay)


async def read_sdongle():
    """Connect to SDongle and read all register batches in one session."""
    try:
        reader, writer = await asyncio.wait_for(
            asyncio.open_connection(args.host, args.port),
            timeout=10,
        )
    except Exception as e:  # noqa: BLE001
        logger.warning(f"SDongle connect failed: {e}")
        return False

    success_count = 0
    fail_count = 0

    for start, count in REGISTER_BATCHES:
        try:
            values = await read_batch(reader, writer, start, count)
            if values:
                async with cache_lock:
                    for i, val in enumerate(values):
                        register_cache[start + i] = val
                success_count += 1
            else:
                fail_count += 1
            await asyncio.sleep(0.05)  # 50ms between reads
        except asyncio.TimeoutError:
            fail_count += 1
        except Exception as e:  # noqa: BLE001
            logger.warning(f"Error reading {start}: {type(e).__name__}")
            fail_count += 1
            break  # Connection likely broken, exit loop

    try:
        writer.close()
        await writer.wait_closed()
    except Exception as e:  # noqa: BLE001
        logger.warning(
            f"Exception occurred during writer clossing {type(e).__name__}: {e}"
        )

    if success_count > 0:
        logger.debug(f"Poll: {success_count}/{success_count + fail_count} batches OK")
    return success_count > 0


async def read_batch(reader, writer, start, count):
    """Read a single register batch. Returns list of values or None."""
    req = struct.pack(">HHHBBHH", 0, 0, 6, args.unit, 3, start, count)
    writer.write(req)
    await writer.drain()

    # Read full response in one go (max 9 header + 125*2 data)
    resp = await asyncio.wait_for(reader.read(9 + count * 2), timeout=3)

    if len(resp) < 9:
        return None

    resp_tx, resp_proto, resp_len, resp_unit, resp_fc, byte_count = struct.unpack(  # noqa: RUF059
        ">HHHBBB", resp[:9]
    )

    if resp_fc >= 0x80:  # Exception
        return None

    data = resp[9:]
    # If we didn't get all data yet, read more
    while len(data) < byte_count:
        more = await asyncio.wait_for(reader.read(byte_count - len(data)), timeout=2)
        if not more:
            break
        data += more

    if len(data) >= count * 2:
        return struct.unpack(">" + "H" * count, data[: count * 2])
    return None


async def handle_client(client_reader, client_writer):
    """Handle a single Modbus TCP client connection."""
    addr = client_writer.get_extra_info("peername")
    logger.debug(f"Client connected: {addr}")

    try:
        while True:
            # Read MBAP header (7 bytes)
            header = await asyncio.wait_for(client_reader.read(7), timeout=60)
            if len(header) < 7:
                break  # Client disconnected

            tx_id, proto, length, unit_id = struct.unpack(">HHHB", header)  # noqa: RUF059

            # Read remaining PDU
            pdu = await asyncio.wait_for(client_reader.read(length - 1), timeout=5)
            if len(pdu) < 1:
                break

            fc = pdu[0]

            if fc == 3 and len(pdu) >= 5:
                # FC3: Read Holding Registers
                reg_addr, reg_count = struct.unpack(">HH", pdu[1:5])

                # Serve from cache
                values = []
                async with cache_lock:
                    for i in range(reg_count):
                        addr_key = reg_addr + i
                        values.append(register_cache.get(addr_key, 0))

                # Build response
                byte_count = reg_count * 2
                resp_pdu = struct.pack(">BB", fc, byte_count)
                resp_pdu += struct.pack(">" + "H" * reg_count, *values)
                resp_header = struct.pack(">HHHB", tx_id, 0, len(resp_pdu) + 1, unit_id)
                client_writer.write(resp_header + resp_pdu)
                await client_writer.drain()

            elif fc == 6 and len(pdu) >= 5:
                # FC6: Write Single Register — pass through to SDongle
                reg_addr, reg_value = struct.unpack(">HH", pdu[1:5])
                logger.info(
                    f"Write request from {addr}: register {reg_addr} = {reg_value}"
                )

                # Forward to SDongle
                write_ok = await forward_write(tx_id, unit_id, reg_addr, reg_value)
                if write_ok:
                    # Echo back (standard Modbus write response)
                    resp_pdu = struct.pack(">BHH", fc, reg_addr, reg_value)
                    resp_header = struct.pack(
                        ">HHHB", tx_id, 0, len(resp_pdu) + 1, unit_id
                    )
                    client_writer.write(resp_header + resp_pdu)
                else:
                    # Error response
                    resp_pdu = struct.pack(">BB", fc + 0x80, 4)  # Device failure
                    resp_header = struct.pack(
                        ">HHHB", tx_id, 0, len(resp_pdu) + 1, unit_id
                    )
                    client_writer.write(resp_header + resp_pdu)
                await client_writer.drain()

            else:
                # Unsupported function code — return exception
                resp_pdu = struct.pack(">BB", fc + 0x80, 1)  # Illegal function
                resp_header = struct.pack(">HHHB", tx_id, 0, len(resp_pdu) + 1, unit_id)
                client_writer.write(resp_header + resp_pdu)
                await client_writer.drain()

    except asyncio.TimeoutError:
        pass  # Client idle timeout
    except ConnectionResetError:
        pass
    except Exception as e:  # noqa: BLE001
        logger.warning(f"Client {addr} error: {type(e).__name__}: {e}")
    finally:
        logger.debug(f"Client disconnected: {addr}")
        try:
            client_writer.close()
            await client_writer.wait_closed()
        except Exception:  # noqa: BLE001
            logger.warning("Exception occurred")


async def forward_write(tx_id, unit_id, reg_addr, reg_value):
    """Forward a write request directly to the SDongle."""
    try:
        reader, writer = await asyncio.wait_for(
            asyncio.open_connection(args.host, args.port),
            timeout=10,
        )
        req = struct.pack(">HHHBBHH", 0, 0, 6, unit_id, 6, reg_addr, reg_value)
        writer.write(req)
        await writer.drain()

        resp = await asyncio.wait_for(reader.read(12), timeout=10)
        writer.close()
        await writer.wait_closed()

        if len(resp) >= 12:
            logger.info(f"Write forwarded OK: register {reg_addr} = {reg_value}")
            return True
        else:
            logger.warning(f"Write forward: short response ({len(resp)} bytes)")
            return False

    except Exception as e:  # noqa: BLE001
        logger.warning(f"Write forward failed: {type(e).__name__}: {e}")
        return False


async def serve():
    init_cache()
    # Start reader loop
    reader_task = asyncio.create_task(reader_loop())
    # Start Modbus TCP server
    server = await asyncio.start_server(handle_client, args.bind_host, args.bind_port)
    stop = asyncio.Event()
    loop = asyncio.get_event_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, stop.set)

    await stop.wait()

    logger.info("Shutting down...")
    reader_task.cancel()
    server.close()
    await server.wait_closed()


if __name__ == "__main__":
    pre_parser = argparse.ArgumentParser(add_help=False)
    pre_parser.add_argument("-c", "--config", default="config.yaml")
    pre_args, _ = pre_parser.parse_known_args()

    # 1. Load data from the target config file (custom or default config.yaml)
    config_data = load_config_file(pre_args.config)

    # 2. Compute dynamic fallbacks (ENV Variable > Config File)

    # Final parser setup supporting full argument overrides
    parser = argparse.ArgumentParser(
        description="Load Modbus settings and registers. Priority: CLI flag > ENV variable > Config file > Default.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "-c",
        "--config",
        default="config.yaml",
        metavar="PATH",
        help="Path to the main application configuration YAML file.",
    )

    parser.add_argument(
        "-r",
        "--registers",
        default=(
            os.environ.get("REGISTERS_FILE")
            or config_data.get("REGISTERS_FILE")
            or "registers.yaml"
        ),
        metavar="PATH",
        help="Path to the registers YAML file.",
    )

    parser.add_argument(
        "--host",
        default=(
            os.environ.get("SUN2000_HOST")
            or config_data.get("SUN2000_HOST")
            or "192.168.1.200"
        ),
        metavar="IP",
        help="Inverter IP address or hostname.",
    )

    parser.add_argument(
        "--port",
        type=int,
        default=int(
            os.environ.get("SUN2000_PORT") or config_data.get("SUN2000_PORT") or "502"
        ),
        metavar="PORT",
        help="Modbus TCP connection port.",
    )

    parser.add_argument(
        "--unit",
        type=int,
        default=int(
            os.environ.get("SUN2000_UNIT_ID")
            or config_data.get("SUN2000_UNIT_ID")
            or "1"
        ),
        metavar="UNIT",
        help="Modbus unit / slave id.",
    )

    parser.add_argument(
        "--bind-host",
        default=(
            os.environ.get("LISTEN_HOST") or config_data.get("LISTEN_HOST") or "0.0.0.0"
        ),
        metavar="IP",
        help="address to serve on.",
    )

    parser.add_argument(
        "--bind-port",
        default=int(
            os.environ.get("LISTEN_PORT") or config_data.get("LISTEN_PORT") or "5502"
        ),
        metavar="IP",
        help="port to serve on.",
    )

    parser.add_argument(
        "--pooling",
        default=int(
            os.environ.get("POLL_INTERVAL") or config_data.get("POLL_INTERVAL") or "10"
        ),
        metavar="TIME",
        help="seconds between polls.",
    )

    parser.add_argument(
        "--loglevel",
        default=os.environ.get("LOG_LEVEL") or config_data.get("LOG_LEVEL") or "INFO",
        metavar="LOG_LEVEL",
        help="Logging level (INFO/DEBUG/WARNING).",
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=args.loglevel,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    logger = logging.getLogger("modbus_cache")

    logger.info(f"Modbus Cache Server listening on {args.bind_host}:{args.bind_port}")
    logger.info(f"Polling SDongle at {args.host}:{args.port} every {args.pooling}")

    REGISTER_BATCHES = load_and_convert(args.registers)

    asyncio.run(serve())
