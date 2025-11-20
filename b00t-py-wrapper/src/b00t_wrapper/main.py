import sys

# The `setuptools-rust` build process compiles the Rust code in `b00t-cli`
# and makes it available as a Python extension module. The `pyproject.toml`
# configures the target to be `b00t_wrapper.b00t_cli`.
from .b00t_cli import b00t_py_run

def main():
    """
    This function is the console script entry point defined in pyproject.toml.
    It passes command-line arguments to the Rust backend and exits with its
    return code.
    """
    try:
        # The first argument to the Rust clap parser is the program name.
        # We'll use "b00t" to simulate the real command.
        args = ["b00t"] + sys.argv[1:]
        
        # Call the Rust function
        exit_code = b00t_py_run(args)
        
        sys.exit(exit_code)
        
    except Exception as e:
        print(f"An error occurred in the Python wrapper: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
