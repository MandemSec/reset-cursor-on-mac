# Reset Cursor on Mac

A tool for resetting Cursor IDE device identifiers on macOS.

## Features

- Resets all device identifiers
- Creates backups automatically
- Includes restore functionality
- Handles code signing
- Simple to use

## Usage

### Reset Device IDs

1. Sign out of Cursor IDE
2. Close Cursor completely
3. Run in Terminal:

```bash
bash reset.sh
```

4. Start Cursor and sign in with a new account

### Restore Original Setup

To restore:

```bash
bash reset.sh --restore
```

### Force Quit

If needed:

```bash
pkill -9 Cursor
```

## Requirements

- macOS 10.13+
- Cursor IDE
- Terminal access

## License

MIT License

Copyright (c) 2025 @mandemsec

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Author

- Twitter: [@siina42069](https://twitter.com/siina42069)
- GitHub: [@mandemsec](https://github.com/mandemsec)
- Date: Sun Mar 16 17:04:20 UTC 2025
