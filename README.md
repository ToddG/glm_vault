# glm_vault

Read and write secrets to/from an encrypted file. This is inspired by Ansible's `Vault` functionality.

The vault is composed of a `toml` file that is encrypted / decrypted using [glm_encrypted_file](https://hexdocs.pm/glm_encrypted_file/).

## Dependencies
* gleam
* [glm_encrypted_file](https://hexdocs.pm/glm_encrypted_file/)
* openssl (see glm_encrypted_file for details)

## Quickstart

The vault file is composed of `key = value` pairs. Keys are strings. Values may be Int, Float, Bool, or String.

* Nested keys are NOT supported.
* Other value types are NOT supported.

Typical usage might use "_" or "." to delineate keys such as :

```
SERVER_ENVIRONMENT_APP_KEY = "some secret"
```


[![Package Version](https://img.shields.io/hexpm/v/glm_vault)](https://hex.pm/packages/glm_vault)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glm_vault/)

```sh
gleam add glm_vault@1
```
```gleam
import gleam/io
import gleam/string
import gleam/dict
import glm_encrypted_file/encfile
import glm_vault/vault
import tom

pub fn main() -> Nil {
  // files
  let encrypted_file = encfile.new_encrypted_file("./encrypted_vault")
  let password_file = encfile.new_password_file("./vault_password")

  // create secrets
  let secrets =
  dict.from_list([
  #("str", tom.String("hello")),
  #("bool", tom.Bool(True)),
  #("int", tom.Int(0)),
  #("float", tom.Float(1.234)),
  ])

  // create a vault
  let v1 = vault.new_vault(secrets)

  // serialize the vault to an encrypted file
  let _ = vault.encrypt(v1, encrypted_file, password_file)

  // de-serialize the vault to an encrypted file
  case vault.decrypt(encrypted_file, password_file){
    Error(_) -> panic
    Ok(v2) -> {
      vault.get_string(v2, "str") |> string.inspect |> io.println
      Nil
    }
  }
}
```

Further documentation can be found at <https://hexdocs.pm/glm_vault>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## TODO
* enable full toml deserialization
* enable nested keys
* add CLI (via clip) for common operations