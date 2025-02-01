def calculate_logical_pixels(physical_width, physical_height, device_pixel_ratio):
    logical_width = physical_width / device_pixel_ratio
    logical_height = physical_height / device_pixel_ratio
    return logical_width, logical_height

# Googleドライブのピクセルサイズ
physical_width = 3120
physical_height = 4160

# デバイスのピクセル密度（例: 3.0）
device_pixel_ratio = 3.0

# 計算
logical_width, logical_height = calculate_logical_pixels(physical_width, physical_height, device_pixel_ratio)

print(f"Flutterの論理ピクセル: {logical_width} x {logical_height}")
