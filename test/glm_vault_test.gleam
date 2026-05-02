import gleam/dict
import gleam/result
import gleeunit
import gleeunit/should
import glm_encrypted_file/encfile
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
  should.equal(should.be_ok(vault.get_string(v, "str")), "hello")
  should.equal(should.be_ok(vault.get_bool(v, "bool")), True)
  should.equal(should.be_ok(vault.get_int(v, "int")), 0)
  should.equal(should.be_ok(vault.get_float(v, "float")), 1.234)
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
  should.equal(should.be_ok(vault.get_string(v, "str")), "goodbye")
  should.equal(should.be_ok(vault.get_bool(v, "bool")), False)
  should.equal(should.be_ok(vault.get_int(v, "int")), 123)
  should.equal(should.be_ok(vault.get_float(v, "float")), 0.1)
}

pub fn new_vault_values_test() {
  let secrets = dict.from_list([])
  let v = vault.new_vault(secrets)
  let v = vault.set_string(v, "str", "goodbye")
  let v = vault.set_bool(v, "bool", False)
  let v = vault.set_int(v, "int", 123)
  let v = vault.set_float(v, "float", 0.1)
  should.equal(should.be_ok(vault.get_string(v, "str")), "goodbye")
  should.equal(should.be_ok(vault.get_bool(v, "bool")), False)
  should.equal(should.be_ok(vault.get_int(v, "int")), 123)
  should.equal(should.be_ok(vault.get_float(v, "float")), 0.1)
}

pub fn missing_keys_test() {
  let secrets = dict.from_list([])
  let v = vault.new_vault(secrets)
  should.be_error(vault.get_string(v, "str"))
  should.be_error(vault.get_bool(v, "bool"))
  should.be_error(vault.get_int(v, "int"))
  should.be_error(vault.get_float(v, "float"))
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
  let encrypted = temporary.file() |> temporary.in_directory(dir)
  use encrypted <- temporary.create(encrypted)
  let encrypted_file = encfile.new_encrypted_file(encrypted)

  let password = temporary.file() |> temporary.in_directory(dir)
  use password <- temporary.create(password)
  let password_file = encfile.new_password_file(password)
  use _ <- result.try(
    simplifile.write(password_file.path, "1234")
    |> result.map_error(fn(e) { vault.UnableToWritePassword(e) }),
  )

  // encrypt the plaintext
  use _ <- result.try(vault.encrypt(v, encrypted_file, password_file))
  // decrypt the encrypted back to plaintext
  use v2 <- result.try(vault.decrypt(encrypted_file, password_file))
  // verify the decrypted against the original plaintext
  should.equal(
    should.be_ok(vault.get_string(v, "str")),
    should.be_ok(vault.get_string(v2, "str")),
  )
  should.equal(
    should.be_ok(vault.get_bool(v, "bool")),
    should.be_ok(vault.get_bool(v2, "bool")),
  )
  should.equal(
    should.be_ok(vault.get_int(v, "int")),
    should.be_ok(vault.get_int(v2, "int")),
  )
  should.equal(
    should.be_ok(vault.get_float(v, "float")),
    should.be_ok(vault.get_float(v2, "float")),
  )
  Ok(Nil)
}
