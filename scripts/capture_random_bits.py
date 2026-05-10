#!/usr/bin/env python3
"""
MURO-TRNG Random Bit Stream Capture Tool

Capture random bits từ FPGA qua UART (configurable baud rate)
Lưu vào file để chạy NIST test hoặc entropy analysis

Hỗ trợ: Windows (COM ports), Linux/Raspberry Pi (/dev/ttyUSB*), macOS (/dev/tty.*)

Cách dùng:
  # Windows
  python capture_random_bits.py -p COM3 -n 10000
  
  # Linux/Pi
  python3 capture_random_bits.py -p /dev/ttyUSB0 -n 10000
  
  # Auto-detect (recommended)
  python3 capture_random_bits.py -n 10000
"""

import serial
import sys
import argparse
from pathlib import Path
import time

def find_com_port():
    """Detect COM port automatically"""
    import platform
    import os
    system = platform.system()
    
    try:
        import serial.tools.list_ports
        ports = list(serial.tools.list_ports.comports())
        
        if not ports:
            print("❌ Không tìm thấy COM port!")
            return None
        
        # Thường FPGA board là FTDI device
        for port in ports:
            desc = port.description.upper() if port.description else ""
            if 'FTDI' in desc or 'CH340' in desc or 'USB' in desc:
                return port.device
        
        # Nếu không tìm thấy FTDI, trả về port đầu tiên
        return ports[0].device
    except ImportError:
        pass
    
    # Fallback: manual device detection
    if system == 'Windows':
        return 'COM3'  # Mặc định Windows
    elif system == 'Darwin':  # macOS
        if os.path.exists('/dev/tty.usbserial-*'):
            return '/dev/tty.usbserial-*'
        return '/dev/tty.usbserial-0001'
    else:  # Linux (Raspberry Pi, etc.)
        # Try common Linux UART devices
        for device in ['/dev/ttyUSB0', '/dev/ttyUSB1', '/dev/ttyACM0', '/dev/ttyACM1']:
            if os.path.exists(device):
                return device
        return '/dev/ttyUSB0'  # Default fallback

def capture_random_bits(port=None, baudrate=115200, num_bytes=1000, output_file='random_bits.bin', timeout=30):
    """
    Capture random bits từ UART
    
    Args:
        port: COM port (auto-detect nếu None)
        baudrate: UART baud rate
        num_bytes: Số byte cần capture (mỗi byte = 8 random bits)
        output_file: Đường dẫn file output
        timeout: Timeout (giây)
    """
    
    if port is None:
        port = find_com_port()
    
    if port is None:
        print("❌ Không tìm thấy COM port!")
        return False
    
    print(f"🔌 Kết nối tới {port} @ {baudrate} baud...")
    
    try:
        ser = serial.Serial(port, baudrate=baudrate, timeout=timeout)
        print(f"✅ Kết nối thành công: {port}")
        
        # Wait for FPGA to be ready
        print("⏳ Chờ FPGA sẵn sàng...")
        time.sleep(0.5)
        
        data = bytearray()
        start_time = time.time()
        bytes_received = 0
        
        print(f"📥 Capture {num_bytes} bytes ({num_bytes * 8} random bits)...")
        
        while bytes_received < num_bytes:
            try:
                byte = ser.read(1)
                if byte:
                    data.extend(byte)
                    bytes_received += 1
                    
                    # Progress indicator
                    if bytes_received % 100 == 0:
                        elapsed = time.time() - start_time
                        throughput = bytes_received / elapsed
                        eta = (num_bytes - bytes_received) / throughput if throughput > 0 else 0
                        print(f"  {bytes_received:5d}/{num_bytes} bytes | {throughput:.1f} B/s | ETA {eta:.1f}s")
            except serial.SerialException as e:
                print(f"❌ Serial error: {e}")
                break
        
        elapsed = time.time() - start_time
        
        # Write to binary file
        with open(output_file, 'wb') as f:
            f.write(data)
        
        # Convert to text format (one bit per line, or comma-separated)
        text_file = output_file.replace('.bin', '.txt')
        with open(text_file, 'w') as f:
            bits = []
            for byte in data:
                for i in range(8):
                    bits.append(str((byte >> i) & 1))
            f.write('\n'.join(bits))
        
        print(f"\n✅ Capture hoàn tất!")
        print(f"   ⏱  Thời gian: {elapsed:.2f} giây")
        print(f"   📊 Dữ liệu: {bytes_received} bytes = {bytes_received * 8} bits")
        print(f"   📁 File binary: {output_file}")
        print(f"   📄 File text: {text_file}")
        print(f"   🔄 Throughput: {bytes_received / elapsed:.1f} B/s ({bytes_received * 8 / elapsed:.0f} bits/s)")
        
        # Basic statistics
        ones = sum(bin(byte).count('1') for byte in data)
        zeros = bytes_received * 8 - ones
        bias = abs(ones - zeros) / (bytes_received * 8)
        
        print(f"\n📊 Statistics:")
        print(f"   Ones:  {ones:6d} ({ones * 100 / (bytes_received * 8):.2f}%)")
        print(f"   Zeros: {zeros:6d} ({zeros * 100 / (bytes_received * 8):.2f}%)")
        print(f"   Bias:  {bias:.4f}")
        
        ser.close()
        return True
        
    except serial.SerialException as e:
        print(f"❌ Lỗi kết nối serial: {e}")
        return False
    except Exception as e:
        print(f"❌ Lỗi: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description='MURO-TRNG Random Bit Stream Capture Tool (Windows/Linux/macOS)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Windows (auto-detect)
  python capture_random_bits.py                      # Auto-detect, 1000 bytes
  python capture_random_bits.py -p COM3 -n 10000    # Specific COM port
  
  # Raspberry Pi / Linux (auto-detect)
  python3 capture_random_bits.py                     # Auto-detect /dev/ttyUSB0
  python3 capture_random_bits.py -p /dev/ttyUSB0 -n 100000
  
  # macOS
  python3 capture_random_bits.py -p /dev/tty.usbserial-001
  
  # High speed (921600 baud)
  python3 capture_random_bits.py -b 921600 -n 100000
  
  # Custom output
  python3 capture_random_bits.py -o nist_test.bin
        """
    )
    
    parser.add_argument('-p', '--port', help='Serial port (default: auto-detect). Examples: COM3 (Windows), /dev/ttyUSB0 (Linux/Pi), /dev/tty.usbserial-001 (macOS)', default=None)
    parser.add_argument('-b', '--baudrate', type=int, help='Baud rate (default: 115200). Note: Must match UART config in FPGA', default=115200)
    parser.add_argument('-n', '--num-bytes', type=int, help='Number of bytes to capture (default: 1000). Each byte = 8 random bits', default=1000)
    parser.add_argument('-o', '--output', help='Output file (default: random_bits.bin). Also generates .txt with ASCII bits', default='random_bits.bin')
    parser.add_argument('-t', '--timeout', type=int, help='Serial timeout in seconds (default: 30). Increase for slow connections', default=30)
    
    args = parser.parse_args()
    
    print("""
╔════════════════════════════════════════════════════╗
║   MURO-TRNG Random Bit Capture Tool               ║
║   Supports: Windows | Linux (Pi) | macOS          ║
║   Baud: Configurable | Format: 8-N-1              ║
╚════════════════════════════════════════════════════╝
    """)
    
    success = capture_random_bits(
        port=args.port,
        baudrate=args.baudrate,
        num_bytes=args.num_bytes,
        output_file=args.output,
        timeout=args.timeout
    )
    
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
