# minidump

[![C++17](https://img.shields.io/badge/C%2B%2B-17-blue.svg)](https://en.wikipedia.org/wiki/C%2B%2B17)
[![CMake](https://img.shields.io/badge/CMake-3.12+-green.svg)](https://cmake.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A portable, production-ready C++17 library for parsing Windows minidump files. Provides complete feature parity with the Python minidump library while offering modern C++ APIs and cross-platform compatibility.

## Features

- **🚀 Modern C++17** - RAII, smart pointers, move semantics, `noexcept` specifications
- **🔧 Production Ready** - Comprehensive error handling, memory safety, extensive testing
- **📦 Easy Integration** - CMake package support, header-only option, no external dependencies
- **🎯 Complete Coverage** - All major minidump stream types (threads, modules, memory, handles, etc.)
- **💾 Memory Operations** - Direct memory access, pointer resolution, string reading
- **🔍 Python Compatible** - Output format matches Python minidump library for validation
- **🌐 Cross Platform** - Works on Windows, Linux, macOS with standard C++17

## Supported Stream Types

- Thread List (ThreadListStream)
- Module List (ModuleListStream) 
- Memory64 List (Memory64ListStream)
- Memory Info List (MemoryInfoListStream)
- System Info (SystemInfoStream)
- Exception (ExceptionStream)
- Handle Data (HandleDataStream)
- Misc Info (MiscInfoStream)

## Quick Start

### Using as Git Submodule (Recommended)

```bash
# Add as submodule
git submodule add https://github.com/example/minidump.git external/minidump
```

```cmake
# In your CMakeLists.txt
add_subdirectory(external/minidump)
target_link_libraries(your_target PRIVATE minidump::minidump)
```

The library automatically disables examples and tests when included as a subdirectory.

### Using CMake Package

```cmake
find_package(minidump REQUIRED)
target_link_libraries(your_target PRIVATE minidump::minidump)
```

### Manual Integration

```cpp
#include "minidump/minidump.hpp"

// Parse a minidump file
auto dump = minidump::minidump_file::parse("crash.dmp");
if (!dump) {
    std::cerr << "Failed to parse minidump file\n";
    return -1;
}

// Access parsed data
const auto& threads = dump->threads();
const auto& modules = dump->modules();
const auto& memory_segments = dump->memory_segments();

// Read memory directly
auto reader = dump->get_reader();
try {
    auto data = reader->read_memory(0x140000000, 256);
    auto pointer = reader->read_pointer(0x140001000);
    auto string = reader->read_string(0x140002000);
} catch (const std::exception& e) {
    std::cerr << "Memory read failed: " << e.what() << "\n";
}

// Find modules and memory regions
const auto* module = reader->find_module_by_name("kernel32.dll");
const auto* segment = reader->find_memory_segment(0x140000000);
```

## Building from Source

### Prerequisites

- C++17 compatible compiler (GCC 7+, Clang 5+, MSVC 2017+)
- CMake 3.12 or later

### Build Steps

```bash
git clone https://github.com/example/minidump.git
cd minidump
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

### Build Options

| Option | Default | Description |
|--------|---------|-------------|
| `MINIDUMP_BUILD_EXAMPLES` | `ON` | Build example programs |
| `MINIDUMP_BUILD_TESTS` | `ON` | Build test suite |

### Installation

```bash
cmake --install . --prefix /usr/local
```

## API Reference

### Core Classes

#### `minidump::minidump_file`

Main parser class for minidump files.

```cpp
// Static factory methods
static std::unique_ptr<minidump_file> parse(const std::string& filename);
static std::unique_ptr<minidump_file> parse_from_buffer(const std::vector<uint8_t>& buffer);

// Data accessors
const minidump_header& header() const noexcept;
const std::vector<thread_info>& threads() const noexcept;
const std::vector<module_info>& modules() const noexcept;
const std::vector<memory_segment>& memory_segments() const noexcept;
const std::vector<memory_region>& memory_regions() const noexcept;
const system_info* get_system_info() const noexcept;
const exception_info* get_exception_info() const noexcept;

// Create memory reader
std::unique_ptr<minidump_reader> get_reader();
```

#### `minidump::minidump_reader`

Memory access operations on the minidump.

```cpp
// Memory operations
std::vector<uint8_t> read_memory(uint64_t virtual_address, size_t size);
std::optional<uint64_t> read_pointer(uint64_t virtual_address);
std::string read_string(uint64_t virtual_address, size_t max_length = 1024);

// Lookup operations
const module_info* find_module_by_address(uint64_t address) const noexcept;
const module_info* find_module_by_name(std::string_view name) const noexcept;
const memory_segment* find_memory_segment(uint64_t address) const noexcept;

// Architecture info
processor_architecture get_architecture() const noexcept;
bool is_64bit() const noexcept;
size_t get_pointer_size() const noexcept;
```

### Data Structures

All structures use snake_case naming and are defined in the `minidump` namespace:

- `minidump_header` - File header information
- `thread_info` - Thread details (ID, TEB, priority, etc.)
- `module_info` - Loaded module information
- `memory_segment` - Memory region data
- `memory_region` - Virtual memory layout
- `system_info` - System and processor information
- `exception_info` - Exception details
- `handle_descriptor` - System handle information

## Error Handling

The library uses exceptions for error conditions:

```cpp
try {
    auto dump = minidump::minidump_file::parse("file.dmp");
    auto reader = dump->get_reader();
    auto data = reader->read_memory(address, size);
} catch (const std::runtime_error& e) {
    std::cerr << "Error: " << e.what() << std::endl;
}
```

Functions marked `noexcept` guarantee no exceptions will be thrown.

## Platform Support

| Platform | Architecture | Compiler | Status |
|----------|-------------|----------|--------|
| Windows | x86, x64 | MSVC 2017+ | ✅ Supported |
| Linux | x86_64, ARM64 | GCC 7+, Clang 5+ | ✅ Supported |
| macOS | x86_64, ARM64 | Clang 5+ | ✅ Supported |

## Performance

- **Zero-copy parsing** where possible
- **Lazy loading** of string data and optional fields
- **Minimal memory overhead** with move semantics
- **Cache-friendly** data structures

## Testing

The library includes comprehensive tests that validate against reference Python output:

```bash
# Run basic tests
ctest

# Compare output with Python minidump library (development)
make compare
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Compatible with and inspired by the [Python minidump library](https://github.com/skelsec/minidump)
- Follows Windows minidump format specification
- Built with modern C++17 best practices