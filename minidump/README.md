# Minidump - Portable C++ Minidump Parser Library

A modern C++17 library for parsing Windows minidump files, compatible with the Python minidump library.

## Features

- **Modern C++17** implementation with RAII, smart pointers, and proper error handling
- **Python-compatible output** for easy validation and comparison
- **Complete minidump parsing** including all major stream types
- **Memory access operations** via minidump_reader class
- **Cross-platform compatibility** with portable file I/O
- **Clean snake_case API** under the `minidump` namespace

## Building

```bash
mkdir build && cd build
cmake ..
make
```

## Usage

```cpp
#include "minidump/minidump.hpp"

auto dump = minidump::minidump_file::parse("dump.dmp");
if (dump) {
    dump->print_all();
    
    auto reader = dump->get_reader();
    auto data = reader->read_memory(0x140000000, 16);
}
```

## Example

```bash
./parse_dump ../dumps/StringEncryptionFun_x64.dmp
```

## Testing

To compare output with Python version:

```bash
make compare
```

## Library Structure

- `minidump::minidump_file` - Main parser class
- `minidump::minidump_reader` - Memory access operations
- `minidump::utils` - Utility functions for formatting and conversion

All structures and functions use snake_case naming convention.