#!/usr/bin/env python3
"""
MURO-TRNG Remote Debug Tool
Tự động kiểm tra tất cả các điểm có thể gặp sự cố khi capture remote

Cách dùng:
  python3 debug_remote.py
  hoặc
  python3 debug_remote.py -p /dev/ttyUSB1  # Nếu dùng port khác
"""

import serial
import sys
import os
import time
import argparse
from pathlib import Path

def print_header(text):
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}")

def print_pass(text):
    print(f"✅ {text}")

def print_fail(text):
    print(f"❌ {text}")

def print_info(text):
    print(f"ℹ️  {text}")

def print_warn(text):
    print(f"⚠️  {text}")

def check_tty_device(port):
    """Kiểm tra nếu /dev/ttyUSB* device tồn tại"""
    print_header("STEP 1: Check UART Device")
    
    if not os.path.exists(port):
        print_fail(f"Device {port} not found!")
        # Try to find alternative
        for i in range(5):
            alt = f"/dev/ttyUSB{i}"
            if os.path.exists(alt):
                print_warn(f"Found alternative: {alt}")
                return alt
        return None
    
    print_pass(f"Device {port} exists")
    
    # Check permissions
    if not os.access(port, os.R_OK | os.W_OK):
        print_fail(f"Permission denied for {port}")
        print_info("Fix with: sudo chmod 666 " + port)
        print_info("Or: sudo usermod -aG dialout $USER")
        return None
    
    print_pass(f"Permissions OK for {port}")
    return port

def check_uart_connection(port, baudrate=115200):
    """Kiểm tra UART port có thể mở được"""
    print_header("STEP 2: Test UART Connection")
    
    try:
        ser = serial.Serial(port, baudrate=baudrate, timeout=2)
        print_pass(f"Connected to {port} @ {baudrate} baud")
        
        # Try to read something
        print_info("Waiting 1 second for data...")
        time.sleep(1)
        
        data = ser.read(100)
        if data:
            print_pass(f"Received {len(data)} bytes: {data[:20].hex()}...")
            ser.close()
            return True, data
        else:
            print_warn("No data received in 1 second")
            ser.close()
            return False, None
            
    except serial.SerialException as e:
        print_fail(f"Cannot open {port}: {e}")
        return False, None
    except Exception as e:
        print_fail(f"Unexpected error: {e}")
        return False, None

def capture_raw_bytes(port, num_bytes=100, timeout=10):
    """Capture raw bytes từ UART"""
    print_header(f"STEP 3: Capture Raw Data ({num_bytes} bytes)")
    
    try:
        ser = serial.Serial(port, 115200, timeout=2)
        data = bytearray()
        start = time.time()
        
        print_info(f"Capturing {num_bytes} bytes with {timeout}s timeout...")
        
        while len(data) < num_bytes and (time.time() - start) < timeout:
            chunk = ser.read(num_bytes - len(data))
            if chunk:
                data.extend(chunk)
                elapsed = time.time() - start
                bps = len(data) / elapsed if elapsed > 0 else 0
                print_info(f"  {len(data):3d}/{num_bytes} bytes | {bps:7.1f} B/s | Time: {elapsed:6.2f}s")
            else:
                time.sleep(0.1)
        
        ser.close()
        
        if len(data) == 0:
            print_fail("No data captured!")
            return None
        
        print_pass(f"Captured {len(data)} bytes in {time.time()-start:.2f}s")
        
        # Display first bytes
        print_info(f"First 16 bytes (hex): {data[:16].hex()}")
        
        # Analyze for obvious problems
        all_zeros = all(b == 0 for b in data)
        all_ones = all(b == 255 for b in data)
        all_same = len(set(data)) == 1
        
        if all_zeros:
            print_warn("⚠️  All bytes are 0x00 - UART might be receiving idle line")
        elif all_ones:
            print_warn("⚠️  All bytes are 0xFF - Check UART polarity?")
        elif all_same:
            print_warn("⚠️  All bytes are the same value - Data not changing")
        else:
            print_pass("Data appears to be varied (good sign)")
        
        return data
        
    except Exception as e:
        print_fail(f"Error during capture: {e}")
        return None

def analyze_uart_timing(data):
    """Phân tích timing của UART data"""
    print_header("STEP 4: Analyze UART Timing")
    
    if not data:
        print_fail("No data to analyze")
        return
    
    # Expected timing at 115200 baud
    expected_bytes_per_sec = 115200 / 10  # 10 bits per byte (START+8DATA+STOP)
    print_info(f"Expected rate: {expected_bytes_per_sec:.0f} bytes/second")
    print_info(f"Expected time per byte: {1000/expected_bytes_per_sec:.2f} ms")
    
    # At 100MHz clock
    print_info(f"Clock cycles per byte: 868 (100MHz / 115200)")
    
    print_info(f"Received: {len(data)} bytes")

def check_data_randomness(data):
    """Kiểm tra entropy của data"""
    print_header("STEP 5: Data Randomness Check")
    
    if not data or len(data) < 100:
        print_warn("Need at least 100 bytes for randomness check")
        return
    
    # Count bit transitions
    byte_list = list(data[:1000])
    bit_count_0 = sum(bin(b).count('0') for b in byte_list)
    bit_count_1 = sum(bin(b).count('1') for b in byte_list)
    total_bits = bit_count_0 + bit_count_1
    
    ratio = bit_count_1 / total_bits if total_bits > 0 else 0
    print_info(f"Bit distribution: {bit_count_0} zeros, {bit_count_1} ones ({ratio*100:.1f}% ones)")
    
    # Should be close to 50%
    if 0.4 < ratio < 0.6:
        print_pass("Bit distribution looks balanced (entropy OK)")
    else:
        print_warn("Bit distribution seems skewed - might indicate problem")

def main():
    parser = argparse.ArgumentParser(
        description='MURO-TRNG Remote Debug Tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python3 debug_remote.py                    # Auto-detect port
  python3 debug_remote.py -p /dev/ttyUSB0   # Specific port
  python3 debug_remote.py -p /dev/ttyUSB0 -n 1000  # Capture 1000 bytes
        '''
    )
    
    parser.add_argument('-p', '--port', type=str, default=None,
                        help='Serial port (default: auto-detect)')
    parser.add_argument('-b', '--baud', type=int, default=115200,
                        help='Baud rate (default: 115200)')
    parser.add_argument('-n', '--num-bytes', type=int, default=1000,
                        help='Number of bytes to capture (default: 1000)')
    parser.add_argument('-o', '--output', type=str, default=None,
                        help='Save captured data to file')
    
    args = parser.parse_args()
    
    print("\n")
    print("╔" + "="*58 + "╗")
    print("║" + " "*58 + "║")
    print("║" + "  MURO-TRNG Remote Debug Tool".center(58) + "║")
    print("║" + "  Automated Diagnostic for Remote Capture Issues".center(58) + "║")
    print("║" + " "*58 + "║")
    print("╚" + "="*58 + "╝")
    
    # Find port
    port = args.port
    if port is None:
        port = "/dev/ttyUSB0"  # Default for Pi
        print_info(f"Port not specified, using default: {port}")
    
    port = check_tty_device(port)
    if not port:
        print_fail("\nCannot proceed without valid serial port!")
        sys.exit(1)
    
    # Test connection
    connected, initial_data = check_uart_connection(port, args.baud)
    
    if not connected:
        print_warn("Initial connection test failed, but continuing...")
    
    # Capture data
    data = capture_raw_bytes(port, num_bytes=args.num_bytes, timeout=30)
    
    if data:
        analyze_uart_timing(data)
        check_data_randomness(data)
        
        # Save if requested
        if args.output:
            with open(args.output, 'wb') as f:
                f.write(data)
            print_pass(f"Data saved to {args.output}")
    
    # Final diagnosis
    print_header("DIAGNOSIS SUMMARY")
    if data and len(data) > 0:
        print_pass("✅ Remote capture is working!")
        print_info(f"Successfully captured {len(data)} bytes")
        if args.output:
            print_info(f"Use this file for NIST testing: {args.output}")
    else:
        print_fail("❌ Remote capture is NOT working")
        print_info("\nNext steps:")
        print_info("1. Power cycle FPGA (unplug USB, wait 2s, plug back)")
        print_info("2. Verify bitstream was loaded successfully")
        print_info("3. Check USB cable connection")
        print_info("4. Run simulation locally to verify RTL")
        print_info("5. See DEBUG_REMOTE_CAPTURE.md for detailed debugging")

if __name__ == '__main__':
    main()
