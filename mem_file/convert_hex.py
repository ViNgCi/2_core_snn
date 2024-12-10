# Input and output file paths
input_file = "D:/TaiLieu/k66/20241/da2/rtl_code/tb_num_inputs.txt"  # File containing decimal numbers (one per line)
output_file = "tb_num_inputs_hex.txt"  # File to save hexadecimal numbers (one per line)

try:
    # Open the input file for reading
    with open(input_file, "r") as infile:
        # Open the output file for writing
        with open(output_file, "w") as outfile:
            # Read each line from the input file
            for line in infile:
                # Strip whitespace and convert to integer
                decimal_number = int(line.strip())
                # Convert the decimal number to hexadecimal
                hex_number = hex(decimal_number)[2:].upper()  # Remove '0x' prefix and convert to uppercase
                # Write the hexadecimal number to the output file
                outfile.write(hex_number + "\n")
    print(f"Conversion completed. Hex numbers saved to {output_file}")
except FileNotFoundError:
    print(f"Error: {input_file} not found!")
except ValueError as e:
    print(f"Error: Invalid decimal number in {input_file} ({e})!")