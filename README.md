# glm_vault

`glm_vault` is a gleam library to enable reading and writing secrets to and from a encrypted files. `glm_vault` is
inspired by `Ansible Vault`, and depends on `glm_encrypted_file` which depends on `openssl`.

## Dependencies

* [gleam](https://gleam.run/)
* [glm_encrypted_file](https://hexdocs.pm/glm_encrypted_file/)
* [openssl](https://docs.openssl.org/master/)
* [toml](https://github.com/lpil/tom)

## Quickstart

Please read the [glm_encrypted_file](https://hexdocs.pm/glm_encrypted_file//README.md) to
understand the implications of using this library.

## Design

### Implementation Details

A vault is an opaque container for a dictionary. Keys are strings, and values are restricted to the following types: String, Bool, Int, Float. The vault is in memory and not encrypted.

The vault can be serialized and deserialized to an encrypted file. Vaults are serialized as `toml`, then written to a temporary file, and subsequently encrypted using openssl. Vaults are deserialized by decrypting an encrypted file, again using openssl. The decrypted plaintext is then parsed as toml and the resulting dictionary is wrapped with a vault.

The other way to create a vault is programatically. Examples of both below:

### Notes

* Nested keys are NOT supported.
* Other value types are NOT supported.

[![Package Version](https://img.shields.io/hexpm/v/glm_vault)](https://hex.pm/packages/glm_vault)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glm_vault/)

```sh
gleam add glm_vault
```

```gleam
import gleam/dict
import gleam/result
import glm_vault/vault
import tom

pub fn main() -> Result(Nil, Nil) {
  // file to serialize a vault to
  let encrypted_file = "./encrypted_vault"

  // the password file must exist and contain some sort of password text
  let password_file = "./vault_password"

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

  // de-serialize the vault from an encrypted file
  case vault.decrypt(encrypted_file, password_file) {
    Error(_) -> panic
    Ok(v2) -> {
      use decrypted_str <- result.try(
        vault.get_string(v2, "str")
        |> result.map_error(fn(_) { Nil }),
      )
      echo "decrypted_str "
      echo decrypted_str
      Ok(Nil)
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
