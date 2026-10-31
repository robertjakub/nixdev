#!/usr/bin/env python3

import argparse
import inspect
import logging
import os
import struct
from http.server import BaseHTTPRequestHandler, HTTPServer

from pymodbus.client import ModbusTcpClient


def get_exact_modbus_keyword(client_instance):
    """Inspects the active pymodbus method parameters at runtime to guarantee compatibility."""
    try:
        sig = inspect.signature(client_instance.read_holding_registers)
        params = sig.parameters.keys()
        if "device_id" in params:
            return "device_id"
        if "slave_id" in params:
            return "slave_id"
    except Exception:  # noqa: BLE001,S110
        pass
    return "slave"


def decode_huawei_int32(reg_list):
    """Decodes two 16-bit registers into a true signed 32-bit integer (Big Endian)."""
    if not reg_list or len(reg_list) < 2:
        return 0
    raw_bytes = struct.pack(">HH", reg_list[0], reg_list[1])
    return struct.unpack(">i", raw_bytes)[0]


def collect_metrics():
    """Connects to the inverter, fetches registers, and returns clean telemetry data."""
    logger.debug(f"connecting to modbus at {args.host}:{args.port}")
    client = ModbusTcpClient(args.host, port=args.port)
    if not client.connect():
        return None

    kw_name = get_exact_modbus_keyword(client)
    try:
        pv_kwargs = {"address": 32064, "count": 2, kw_name: int(args.slave)}
        grid_kwargs = {"address": 37113, "count": 2, kw_name: int(args.slave)}

        pv_response = client.read_holding_registers(**pv_kwargs)
        grid_response = client.read_holding_registers(**grid_kwargs)

        if pv_response.isError() or grid_response.isError():
            return None

        pv_power = decode_huawei_int32(pv_response.registers)
        grid_power = decode_huawei_int32(grid_response.registers)

        if pv_power < 0:
            logger.info("PV real-time power lower than 0W, check Inverter")
            return None

        if pv_power > int(args.peak):
            logger.info(
                f"PV real-time power ({pv_power}) exceeds the PEAK value, check Inverter"
            )
            return None

        if grid_power > int(args.grid_peak) or grid_power < -int(args.grid_peak):
            logger.info(
                f"Grid ({abs(grid_power)}) exceeds the maximum of the line ({args.grid_peak})"
            )
            return None

        home_load = pv_power - grid_power

        if home_load < 0:
            logger.info(f"Home {home_load} must be 0 or greater")
            return None

        # Separate grid power into explicit export/import variables for easy graphing
        grid_export = max(0, grid_power)
        grid_import = max(0, -grid_power)

        logger.debug(f"pv: {pv_power} grid: {grid_power} home: {home_load}")
        logger.debug(f"grid, export: {grid_export} import: {grid_import}")

        return {
            "huawei_pv_generation_watts": pv_power,
            "huawei_grid_net_watts": grid_power,
            "huawei_grid_export_watts": grid_export,
            "huawei_grid_import_watts": grid_import,
            "huawei_home_consumption_watts": home_load,
        }
    except Exception as e:  # noqa: BLE001
        logger.info(f"error fetching modbus data: {e}")
        return None
    finally:
        client.close()


class PrometheusMetricsHandler(BaseHTTPRequestHandler):
    """Serves the plain-text metrics format required by Prometheus."""

    def do_GET(self):
        if self.path == "/metrics":
            data = collect_metrics()

            if data is None:
                self.send_response(503)
                self.end_headers()
                self.wfile.write(b"Error collecting metrics from inverter")
                return

            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
            self.end_headers()

            # Format the output into standard Prometheus exposition format strings
            output = []
            for metric_name, value in data.items():
                output.append(
                    f"# HELP {metric_name} Current real-time power value in Watts"
                )
                output.append(f"# TYPE {metric_name} gauge")
                output.append(f"{metric_name} {value}")

            self.wfile.write("\n".join(output).encode("utf-8") + b"\n")
        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Not Found. Use /metrics")

    def log_message(self, format, *args):
        """Silences standard HTTP connection logging to keep your terminal output clean."""
        return


if __name__ == "__main__":
    pre_parser = argparse.ArgumentParser(add_help=False)
    pre_args, _ = pre_parser.parse_known_args()

    parser = argparse.ArgumentParser(
        description="🚀 Huawei Solar Prometheus Exporter.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    parser.add_argument(
        "--loglevel",
        default=os.environ.get("LOG_LEVEL") or "INFO",
        metavar="LOG_LEVEL",
        help="Logging level (INFO/DEBUG/WARNING).",
    )

    parser.add_argument(
        "--host",
        default="127.0.0.1",
        metavar="IP",
        help="Inverter IP address.",
    )

    parser.add_argument(
        "--port",
        default="5502",
        metavar="PORT",
        help="Inverter TCP Port.",
    )

    parser.add_argument(
        "--slave",
        default="1",
        metavar="ID",
        help="Inverter Modbus SLAVE_ID.",
    )

    parser.add_argument(
        "--bind-host",
        default="0.0.0.0",
        metavar="IP",
        help="Listen on IP.",
    )

    parser.add_argument(
        "--bind-port",
        default="9300",
        metavar="PORT",
        help="Listen on PORT.",
    )

    parser.add_argument(
        "-m",
        "--peak",
        default="6000",
        metavar="Watt",
        help="Inverter Max PV peak.",
    )

    parser.add_argument(
        "-g",
        "--grid-peak",
        default="12000",
        metavar="Watt",
        help="Max grid peak.",
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=args.loglevel,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    logger = logging.getLogger("hspe")

    logger.info(
        f"Huawei Solar Prometheus Exporter listening on {args.bind_host}:{args.bind_port}"
    )

    logger.info(f"Inverter maximum kWp: {args.peak}")

    server = HTTPServer((args.bind_host, int(args.bind_port)), PrometheusMetricsHandler)
    logger.info("Server running")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Stopping exporter server...")
        server.server_close()
