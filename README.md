# TOTP

Time-Based One-Time Password Generator

## Usage

Takes a key in base32 from stdin and writes a one time password to stdout.

```sh
$ echo $SOME_KEY | totp
956181
```

```sh
# run
$ echo $SOME_KEY | zig build run

# test
$ zig build test

# compile
$ zig build
```

## References

- [RFC-6238: TOTP: Time-Based One-Time Password Algorithm](https://www.rfc-editor.org/info/rfc6238/)
- [RFC 4226: HOTP: An HMAC-Based One-Time Password Algorithm](https://www.rfc-editor.org/info/rfc4226/)
- [RFC 4648: The Base16, Base32, and Base64 Data Encodings](https://www.rfc-editor.org/info/rfc4648/)
