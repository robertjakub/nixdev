#!/usr/bin/env python3
import inspect
import struct
from http.server import BaseHTTPRequestHandler, HTTPServer

from pymodbus.client import ModbusTcpClient

# --- Configuration Profile ---
INVERTER_IP = "127.0.0.1"
PORT = 5502
SLAVE_ID = 1
LISTEN_PORT = 9300  # The port Prometheus will scrape


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
    client = ModbusTcpClient(INVERTER_IP, port=PORT)
    if not client.connect():
        return None

    kw_name = get_exact_modbus_keyword(client)
    try:
        pv_kwargs = {"address": 32064, "count": 2, kw_name: SLAVE_ID}
        grid_kwargs = {"address": 37113, "count": 2, kw_name: SLAVE_ID}

        pv_response = client.read_holding_registers(**pv_kwargs)
        grid_response = client.read_holding_registers(**grid_kwargs)

        if pv_response.isError() or grid_response.isError():
            return None

        pv_power = decode_huawei_int32(pv_response.registers)
        grid_power = decode_huawei_int32(grid_response.registers)
        home_load = pv_power - grid_power

        # Separate grid power into explicit export/import variables for easy graphing
        grid_export = max(0, grid_power)
        grid_import = max(0, -grid_power)

        return {
            "huawei_pv_generation_watts": pv_power,
            "huawei_grid_net_watts": grid_power,
            "huawei_grid_export_watts": grid_export,
            "huawei_grid_import_watts": grid_import,
            "huawei_home_consumption_watts": home_load,
        }
    except Exception:  # noqa: BLE001
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


def run_server():
    server = HTTPServer(("0.0.0.0", LISTEN_PORT), PrometheusMetricsHandler)
    print(
        f"🚀 Huawei Solar Prometheus Exporter actively listening on http://localhost:{LISTEN_PORT}/metrics"
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping exporter server...")
        server.server_close()


if __name__ == "__main__":
    run_server()
