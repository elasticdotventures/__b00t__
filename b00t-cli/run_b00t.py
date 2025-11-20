"""
Python wrapper to execute the b00t-cli Rust library via FFI.

This script loads the compiled `b00t_cli.dll` dynamic library,
passes command-line arguments to it, and executes the main CLI logic.
This allows the Rust application to be run in environments where executing
unsigned .exe files is restricted, but running Python scripts is allowed.
"""

import sys
import ctypes
import os
import platform

def main():
    """
    Loads the Rust library, prepares the arguments, and calls the FFI function.
    """
    try:
        # Determine the correct library file based on the operating system
        if platform.system() == "Windows":
            lib_filename = "b00t_cli.dll"
        elif platform.system() == "Linux":
            lib_filename = "libb00t_cli.so"
        elif platform.system() == "Darwin": # macOS
            lib_filename = "libb00t_cli.dylib"
        else:
            raise OSError(f"Unsupported operating system: {platform.system()}")

        # Construct the path to the library, assuming it's in the standard cargo target/release directory
        # relative to this script's location.
        # For this to work, the script should be in the `b00t-cli` directory.
        script_dir = os.path.dirname(os.path.realpath(__file__))
        lib_path = os.path.join(script_dir, "target", "release", lib_filename)

        if not os.path.exists(lib_path):
            print(f"Error: Library not found at {lib_path}", file=sys.stderr)
            print("Please build the Rust project first using: cargo build --release", file=sys.stderr)
            sys.exit(1)

        # Load the shared library
        b00t_lib = ctypes.CDLL(lib_path)

        # Define the function signature from the Rust code
        # extern "C" fn b00t_cli_run(args_str: *const c_char) -> i32
        b00t_cli_run = b00t_lib.b00t_cli_run
        b00t_cli_run.argtypes = [ctypes.c_char_p]
        b00t_cli_run.restype = ctypes.c_int

        # The first argument to the Rust clap parser is the program name.
        # We'll use "b00t" to simulate the real command.
        args_list = ["b00t"] + sys.argv[1:]

        # Join arguments into a single space-separated string
        args_str = " ".join(args_list)

        # Execute the Rust function
        exit_code = b00t_cli_run(args_str.encode('utf-8'))

        # Exit with the same code as the Rust library
        sys.exit(exit_code)

    except (OSError, AttributeError) as e:
        print(f"Error loading or calling the Rust library: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
