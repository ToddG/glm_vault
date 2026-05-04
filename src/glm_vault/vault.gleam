/// A library to read/write secrets to/from encrypted files.
import gleam/bool
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import glm_encrypted_file/openssl
import simplifile
import temporary
import tom.{type Toml}

/// A vault is an opaque datatype that contains the secrets.
pub opaque type Vault {
  Vault(secrets: dict.Dict(String, Toml))
}

/// Create a new vault.
pub fn new_vault(secrets: dict.Dict(String, Toml)) -> Vault {
  Vault(secrets:)
}

/// Vault Errors
pub type VaultError {
  UnableToSerializeUnsupportdType(Toml)
  UnableToGetFromVault(tom.GetError)
  UnableToDecryptFile(openssl.OpenSslError, String, String)
  UnableToParseDecryptedToml(tom.ParseError, String, String)
  UnableToEncryptFile(simplifile.FileError)
  UnableToGetFromDict(String)
}

/// Decrypt an encrypted file and return a vault instance.
pub fn decrypt(
  encrypted_file: String,
  password_file: String,
) -> Result(Vault, VaultError) {
  use plaintext: String <- result.try(
    openssl.decrypt(encrypted_file, password_file)
    |> result.map(fn(plaintext) { plaintext })
    |> result.map_error(UnableToDecryptFile(_, encrypted_file, password_file)),
  )
  plaintext
  |> tom.parse
  |> result.map_error(UnableToParseDecryptedToml(
    _,
    encrypted_file,
    password_file,
  ))
  |> result.map(fn(secrets) { Vault(secrets:) })
}

/// Serialize dict that contains these datatypes: string, int, float, bool.
/// Nested datatypes and arrays are not supported.
fn serialize(d: dict.Dict(String, Toml)) -> Result(List(String), VaultError) {
  dict.keys(d)
  |> list.map(fn(key) { serialize_item(d, key) })
  |> result.all
}

/// Serialize a single item, so long as it is one of these supported datatypes:  string, int, float, bool.
///
/// Implementation details that should not concern the consumer:
/// Items are serialized as `key = value` pairs in `toml` format.
fn serialize_item(
  d: dict.Dict(String, Toml),
  key: String,
) -> Result(String, VaultError) {
  use value <- result.try(
    dict.get(d, key)
    |> result.map_error(fn(_) { UnableToGetFromDict(key) }),
  )

  case value {
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

/// Serialize a vault instance to a temporary file, then encrypt that file and delete the temporary file.
/// Upon success, an encrypted file is created that contains the serialized contents of the vault.
pub fn encrypt(
  vault: Vault,
  encrypted_file: String,
  password_file: String,
) -> Result(Nil, VaultError) {
  let result = {
    // create a temporary file to hold plaintext secrets
    use temp_file <- temporary.create(temporary.file())
    let rw = set.from_list([simplifile.Read, simplifile.Write])
    let none = set.from_list([])
    use _ <- result.try(simplifile.set_permissions(
      temp_file,
      simplifile.FilePermissions(rw, none, none),
    ))

    // write secrets to temporary file
    let _ =
      vault.secrets
      |> serialize
      |> result.map(string.join(_, "\n"))
      |> result.map(simplifile.write(temp_file, _))
      |> result.map(fn(_) {
        // encrypt the temporary file
        let _ = openssl.encrypt(temp_file, encrypted_file, password_file)
      })
    // the temporary file is disposed of when we exit this scope
    Ok(Nil)
  }
  case result {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(UnableToEncryptFile(e))
  }
}

pub fn get_int(v: Vault, key: String) -> Result(Int, VaultError) {
  tom.get_int(v.secrets, [key])
  |> result.map_error(UnableToGetFromVault)
}

pub fn set_int(v: Vault, key: String, value: Int) -> Vault {
  let secrets = dict.insert(v.secrets, key, tom.Int(value))
  Vault(secrets:)
}

pub fn get_float(v: Vault, key: String) -> Result(Float, VaultError) {
  tom.get_float(v.secrets, [key])
  |> result.map_error(UnableToGetFromVault)
}

pub fn set_float(v: Vault, key: String, value: Float) -> Vault {
  let secrets = dict.insert(v.secrets, key, tom.Float(value))
  Vault(secrets:)
}

pub fn get_bool(v: Vault, key: String) -> Result(Bool, VaultError) {
  tom.get_bool(v.secrets, [key])
  |> result.map_error(UnableToGetFromVault)
}

pub fn set_bool(v: Vault, key: String, value: Bool) -> Vault {
  let secrets = dict.insert(v.secrets, key, tom.Bool(value))
  Vault(secrets:)
}

pub fn get_string(v: Vault, key: String) -> Result(String, VaultError) {
  tom.get_string(v.secrets, [key])
  |> result.map_error(UnableToGetFromVault)
}

pub fn set_string(v: Vault, key: String, value: String) -> Vault {
  let secrets = dict.insert(v.secrets, key, tom.String(value))
  Vault(secrets:)
}
