import gleam/dict
import gleam/result
import gleeunit
import glm_vault/vault
import simplifile
import temporary
import tom

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn vault_from_dict_test() {
  let secrets =
    dict.from_list([
      #("str", tom.String("hello")),
      #("bool", tom.Bool(True)),
      #("int", tom.Int(0)),
      #("float", tom.Float(1.234)),
    ])
  let v = vault.new_vault(secrets)
  let assert Ok(value) = vault.get_string(v, "str")
  assert value == "hello"
  let assert Ok(value) = vault.get_bool(v, "bool")
  assert value == True
  let assert Ok(value) = vault.get_int(v, "int")
  assert value == 0
  let assert Ok(value) = vault.get_float(v, "float")
  assert value == 1.234
}

pub fn overwrite_vault_values_test() {
  let secrets =
    dict.from_list([
      #("str", tom.String("hello")),
      #("bool", tom.Bool(True)),
      #("int", tom.Int(0)),
      #("float", tom.Float(1.234)),
    ])
  let v = vault.new_vault(secrets)
  let v = vault.set_string(v, "str", "goodbye")
  let v = vault.set_bool(v, "bool", False)
  let v = vault.set_int(v, "int", 123)
  let v = vault.set_float(v, "float", 0.1)
  let assert Ok(value) = vault.get_string(v, "str")
  assert value == "goodbye"
  let assert Ok(value) = vault.get_bool(v, "bool")
  assert value == False
  let assert Ok(value) = vault.get_int(v, "int")
  assert value == 123
  let assert Ok(value) = vault.get_float(v, "float")
  assert value == 0.1
}

pub fn new_vault_values_test() {
  let secrets = dict.from_list([])
  let v = vault.new_vault(secrets)
  let v = vault.set_string(v, "str", "goodbye")
  let v = vault.set_bool(v, "bool", False)
  let v = vault.set_int(v, "int", 123)
  let v = vault.set_float(v, "float", 0.1)
  let assert Ok(value) = vault.get_string(v, "str")
  assert value == "goodbye"
  let assert Ok(value) = vault.get_bool(v, "bool")
  assert value == False
  let assert Ok(value) = vault.get_int(v, "int")
  assert value == 123
  let assert Ok(value) = vault.get_float(v, "float")
  assert value == 0.1
}

pub fn missing_keys_test() {
  let secrets = dict.from_list([])
  let v = vault.new_vault(secrets)
  let assert Error(_) = vault.get_string(v, "str")
  let assert Error(_) = vault.get_bool(v, "bool")
  let assert Error(_) = vault.get_int(v, "int")
  let assert Error(_) = vault.get_float(v, "float")
}

pub fn roundtrip_encrypt_decrypt_test() {
  let secrets =
    dict.from_list([
      #("str", tom.String("hello")),
      #("bool", tom.Bool(True)),
      #("int", tom.Int(0)),
      #("float", tom.Float(1.234)),
    ])
  let v = vault.new_vault(secrets)
  use dir <- temporary.create(temporary.directory())
  let encrypted_file = temporary.file() |> temporary.in_directory(dir)
  use encrypted_file <- temporary.create(encrypted_file)

  let password = temporary.file() |> temporary.in_directory(dir)
  use password_file <- temporary.create(password)

  let _ = case simplifile.write(password_file, "1234") {
    Error(_) -> panic
    Ok(_) -> {
      // encrypt the plaintext
      use _ <- result.try(vault.encrypt(v, encrypted_file, password_file))
      // decrypt the encrypted back to plaintext
      use v2 <- result.try(vault.decrypt(encrypted_file, password_file))
      // verify the decrypted against the original plaintext
      let assert Ok(value1) = vault.get_string(v, "str")
      let assert Ok(value2) = vault.get_string(v2, "str")
      assert value1 == value2
      let assert Ok(value1) = vault.get_bool(v, "bool")
      let assert Ok(value2) = vault.get_bool(v2, "bool")
      assert value1 == value2
      let assert Ok(value1) = vault.get_int(v, "int")
      let assert Ok(value2) = vault.get_int(v2, "int")
      assert value1 == value2
      let assert Ok(value1) = vault.get_float(v, "float")
      let assert Ok(value2) = vault.get_float(v2, "float")
      assert value1 == value2
      Ok(Nil)
    }
  }
}

pub fn example_code() -> Result(Nil, Nil) {
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
