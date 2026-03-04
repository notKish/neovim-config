#!/usr/bin/env python3
"""
Test file for Python debugging in Neovim
Set breakpoints and debug this file to test the DAP setup
"""

def calculate_sum(a, b):
    """Add two numbers together"""
    result = a + b  # Set breakpoint here: <leader>db
    return result

def calculate_product(a, b):
    """Multiply two numbers"""
    result = a * b  # Set breakpoint here
    return result

def process_numbers(numbers):
    """Process a list of numbers"""
    total = 0
    for num in numbers:  # Set breakpoint here to inspect loop
        total += num
    return total

def main():
    """Main function to test debugging"""
    x = 10
    y = 20
    
    # Set breakpoint here to inspect variables
    sum_result = calculate_sum(x, y)
    print(f"Sum of {x} and {y}: {sum_result}")
    
    product_result = calculate_product(x, y)
    print(f"Product of {x} and {y}: {product_result}")
    
    numbers = [1, 2, 3, 4, 5]
    total = process_numbers(numbers)
    print(f"Sum of {numbers}: {total}")

if __name__ == "__main__":
    main()

