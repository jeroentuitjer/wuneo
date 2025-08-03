#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw, ImageFont
import math

def create_icon(size, scale=1):
    """Create an iOS app icon with the WUNEO ASCII art"""
    actual_size = int(size * scale)
    
    # Create a black background
    img = Image.new('RGB', (actual_size, actual_size), 'black')
    draw = ImageDraw.Draw(img)
    
    # Try to use a monospace font
    try:
        # Much smaller font size with more padding
        if actual_size <= 40:
            font_size = max(1, actual_size // 35)
        elif actual_size <= 80:
            font_size = max(2, actual_size // 40)
        elif actual_size <= 120:
            font_size = max(3, actual_size // 45)
        else:
            font_size = max(4, actual_size // 50)
            
        font = ImageFont.truetype("/System/Library/Fonts/Monaco.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Courier.ttf", font_size)
        except:
            font = ImageFont.load_default()
    
    # WUNEO ASCII Art - simplified for better scaling
    lines = [
        '██     ██ ██   ██ ██   ██ ███████ ██████',
        '██  █  ██ ██   ██ ███  ██ ██      ██    ██',
        '██ ███ ██ ██   ██ ████ ██ █████   ██    ██',
        '████ ██ ██   ██ ██ ████ ██      ██    ██',
        ' ██ ██  ██████  ██  ███ ███████  ██████',
    ]
    
    # For very small icons, use a much more compact version
    if actual_size < 80:
        lines = [
            '██ ██ ██ ██ ███████ ██████',
            '██ ██ ██ ███ ██ ██    ██',
            '██ ████ ██ █████ ██    ██',
            '████ ██ ██ ██ ██    ██',
            ' ██ ██████ ███████ ██████',
        ]
    
    # For extremely small icons, use just the letters
    if actual_size < 50:
        lines = [
            'WUNEO',
            'SYSTEM',
        ]
    
    # Calculate total height of text
    line_height = font_size + 1
    total_height = len(lines) * line_height
    
    # Add padding to ensure text doesn't touch edges
    padding = actual_size // 8
    available_height = actual_size - (2 * padding)
    
    # Scale down if text is too tall
    if total_height > available_height:
        scale_factor = available_height / total_height
        font_size = int(font_size * scale_factor)
        line_height = font_size + 1
        total_height = len(lines) * line_height
        
        # Recreate font with new size
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Monaco.ttf", font_size)
        except:
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Courier.ttf", font_size)
            except:
                font = ImageFont.load_default()
    
    # Start position (center vertically with padding)
    y_start = (actual_size - total_height) // 2
    
    # Draw each line
    for i, line in enumerate(lines):
        # Get text size
        bbox = draw.textbbox((0, 0), line, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        # Center horizontally with padding
        x = (actual_size - text_width) // 2
        y = y_start + (i * line_height)
        
        # Ensure text doesn't go outside bounds
        if x < padding:
            x = padding
        if x + text_width > actual_size - padding:
            x = actual_size - text_width - padding
        
        # Draw text in white
        draw.text((x, y), line, fill='white', font=font)
    
    return img

def main():
    """Generate all iOS app icons"""
    # Define iOS icon sizes
    icon_sizes = [
        (20, 1), (20, 2), (20, 3),
        (29, 1), (29, 2), (29, 3),
        (40, 1), (40, 2), (40, 3),
        (60, 2), (60, 3),
        (76, 1), (76, 2),
        (83.5, 2),
        (1024, 1),
    ]
    
    # Create output directory
    output_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate each icon
    for size, scale in icon_sizes:
        img = create_icon(size, scale)
        
        # Save with proper filename
        filename = f"Icon-App-{int(size)}x{int(size)}@{scale}x.png"
        filepath = os.path.join(output_dir, filename)
        img.save(filepath, "PNG")
        
        print(f"Generated: {filename}")
    
    print("All iOS app icons generated successfully!")

if __name__ == "__main__":
    main() 