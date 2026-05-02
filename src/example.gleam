import gleam/dict
import gleam/io
import gleam/string
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
  case vault.decrypt(encrypted_file, password_file) {
    Error(_) -> panic
    Ok(v2) -> {
      vault.get_string(v2, "str") |> string.inspect |> io.println
      Nil
    }
  }
}
