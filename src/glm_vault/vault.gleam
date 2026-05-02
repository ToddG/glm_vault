import gleam/bool
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import glm_encrypted_file/encfile
import logging
import simplifile
import tom.{type Toml}

import temporary

pub opaque type Vault {
  Vault(secrets: dict.Dict(String, Toml))
}

pub fn new_vault(secrets: dict.Dict(String, Toml)) -> Vault {
  Vault(secrets:)
}

pub type VaultError {
  UnableToDecryptFile(
    encfile.EncFileError,
    encfile.EncryptedFile,
    encfile.PasswordFile,
  )
  UnableToParseDecryptedToml(
    tom.ParseError,
    encfile.EncryptedFile,
    encfile.PasswordFile,
  )
  UnableToSerializeItemGetError(Nil, String)
  UnableToSerializeUnsupportdType(Toml)
  UnableToGetIntFromVault(tom.GetError)
  UnableToGetFloatFromVault(tom.GetError)
  UnableToGetBoolFromVault(tom.GetError)
  UnableToGetStringFromVault(tom.GetError)
  UnableToEncryptFile(encfile.EncryptedFile)
  UnableToWritePassword(simplifile.FileError)
}

pub fn decrypt(
  encrypted_file: encfile.EncryptedFile,
  password_file: encfile.PasswordFile,
) -> Result(Vault, VaultError) {
  use plaintext <- result.try(
    encfile.decrypt(encrypted_file, password_file)
    |> result.map(fn(plaintext) {
      logging.log(
        logging.Debug,
        "decrypted encrypted file: "
          <> encrypted_file.path
          <> ", using password file: "
          <> password_file.path,
      )
      plaintext
    })
    |> result.map_error(UnableToDecryptFile(_, encrypted_file, password_file)),
  )

  plaintext
  |> tom.parse
  |> result.map_error(UnableToParseDecryptedToml(
    _,
    encrypted_file,
    password_file,
  ))
  |> result.map(fn(secrets) {
    logging.log(
      logging.Debug,
      "parsed encrypted file: "
        <> encrypted_file.path
        <> ", using password file: "
        <> password_file.path,
    )
    Vault(secrets:)
  })
}

// TODO: replace this janky serialization code with proper (full) toml serialization
fn serialize(d: dict.Dict(String, Toml)) -> Result(List(String), VaultError) {
  dict.keys(d)
  |> list.map(fn(key) { serialize_item(key, dict.get(d, key)) })
  |> result.all
}

// TODO: replace this janky serialization code with proper (full) toml serialization
fn serialize_item(
  key: String,
  value: Result(Toml, Nil),
) -> Result(String, VaultError) {
  case value {
    Error(e) -> Error(UnableToSerializeItemGetError(e, key))
    Ok(found) ->
      case found {
        tom.Int(x) -> {
          Ok(key <> " = " <> int.to_string(x))
        }
        tom.String(x) -> {
          Ok(key <> " = " <> x)
        }
        tom.Bool(x) -> {
          Ok(key <> " = " <> x |> bool.to_string)
        }
        tom.Float(x) -> {
          Ok(key <> " = " <> x |> float.to_string)
        }
        t -> Error(UnableToSerializeUnsupportdType(t))
      }
  }
}

pub fn encrypt(
  vault: Vault,
  encrypted_file: encfile.EncryptedFile,
  password_file: encfile.PasswordFile,
) -> Result(Nil, VaultError) {
  let result = {
    use temp_file <- temporary.create(temporary.file())
    logging.log(
      logging.Debug,
      "opened temp file to write plaintext to: " <> temp_file,
    )
    // write secrets to temporary file
    let _ =
      vault.secrets
      |> serialize
      |> result.map(string.join(_, "\n"))
      |> result.map(simplifile.write(temp_file, _))
      |> result.map(fn(_) {
        // encrypt the temporary file
        let _ =
          encfile.encrypt(
            encfile.new_plaintext_file(temp_file),
            encrypted_file,
            password_file,
          )
        logging.log(
          logging.Debug,
          "encrypted plaintext and wrote to: " <> encrypted_file.path,
        )
      })
    // the temporary file is disposed of when we exit this scope
    Nil
  }
  case result {
    Ok(vault_result) -> Ok(vault_result)
    Error(_temporary_file_error) -> Error(UnableToEncryptFile(encrypted_file))
  }
}

pub fn get_int(v: Vault, key: String) -> Result(Int, VaultError) {
  tom.get_int(v.secrets, [key])
  |> result.map_error(UnableToGetIntFromVault)
}

pub fn set_int(v: Vault, key: String, value: Int) -> Vault {
  let secrets = dict.insert(v.secrets, key, tom.Int(value))
  Vault(secrets:)
}

pub fn get_float(v: Vault, key: String) -> Result(Float, VaultError) {
  tom.get_float(v.secrets, [key])
  |> result.map_error(UnableToGetFloatFromVault)
}

pub fn set_float(v: Vault, key: String, value: Float) -> Vault {
  let secrets = dict.insert(v.secrets, key, tom.Float(value))
  Vault(secrets:)
}

pub fn get_bool(v: Vault, key: String) -> Result(Bool, VaultError) {
  tom.get_bool(v.secrets, [key])
  |> result.map_error(UnableToGetBoolFromVault)
}

pub fn set_bool(v: Vault, key: String, value: Bool) -> Vault {
  let secrets = dict.insert(v.secrets, key, tom.Bool(value))
  Vault(secrets:)
}

pub fn get_string(v: Vault, key: String) -> Result(String, VaultError) {
  tom.get_string(v.secrets, [key])
  |> result.map_error(UnableToGetStringFromVault)
}

pub fn set_string(v: Vault, key: String, value: String) -> Vault {
  let secrets = dict.insert(v.secrets, key, tom.String(value))
  Vault(secrets:)
}
