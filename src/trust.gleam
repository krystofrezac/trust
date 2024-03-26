import gleam/dynamic
import gleam/dict
import gleam/string
import gleam/list
import gleam/int
import gleam/result
import gleam/bool

pub type DecodeErrorKind {
  TypeMismatch(expected: String, found: String)
  FieldNotFound
  NotInStringEnum(available_keys: List(String), found: String)
  StringLenError(expected_length: Int, current_length: Int)
  StringMinLenError(min_length: Int, current_length: Int)
  StringMaxLenError(max_length: Int, current_length: Int)
}

pub type DecodeError {
  DecodeError(message: String, path: List(String), error_kind: DecodeErrorKind)
}

pub type DecodeResult(t) =
  Result(t, List(DecodeError))

pub type Decoder(t) =
  fn(dynamic.Dynamic) -> DecodeResult(t)

pub fn bool_with_message(message: String) -> Decoder(Bool) {
  create_basic_decoder(message, "Bool", dynamic.bool)
}

pub fn bool(data: dynamic.Dynamic) -> DecodeResult(Bool) {
  bool_with_message("Expected type Bool")(data)
}

pub fn bool_literal_with_message(value: Bool, message: String) -> Decoder(Bool) {
  create_literal_decoder(message, value, bool.to_string, dynamic.bool)
}

pub fn bool_literal(value: Bool) -> Decoder(Bool) {
  bool_literal_with_message(value, "Expected " <> bool.to_string(value))
}

pub fn string_with_message(message: String) -> Decoder(String) {
  create_basic_decoder(message, "String", dynamic.string)
}

pub fn string(data: dynamic.Dynamic) -> DecodeResult(String) {
  string_with_message("Expected type String")(data)
}

pub fn string_literal_with_message(
  value: String,
  message: String,
) -> Decoder(String) {
  create_literal_decoder(
    message,
    value,
    fn(v) { "\"" <> v <> "\"" },
    dynamic.string,
  )
}

pub fn string_literal(value: String) -> Decoder(String) {
  string_literal_with_message(value, "Expected \"" <> value <> "\"")
}

pub fn string_len_with_message(
  source: Decoder(String),
  len: Int,
  message: String,
) -> Decoder(String) {
  fn(data) {
    use decoded_data <- result.try(source(data))

    let current_length = string.length(decoded_data)
    let is_in_limit = current_length == len

    case is_in_limit {
      True -> Ok(decoded_data)
      False ->
        Error([
          DecodeError(
            message: message,
            error_kind: StringLenError(
              expected_length: len,
              current_length: current_length,
            ),
            path: [],
          ),
        ])
    }
  }
}

pub fn string_len(source: Decoder(String), len: Int) -> Decoder(String) {
  string_len_with_message(
    source,
    len,
    "String has wrong length. Expected length is " <> int.to_string(len),
  )
}

pub fn string_min_len_with_message(
  source: Decoder(String),
  min_len: Int,
  message: String,
) -> Decoder(String) {
  fn(data) {
    use decoded_data <- result.try(source(data))

    let current_length = string.length(decoded_data)
    let is_in_limit = current_length >= min_len

    case is_in_limit {
      True -> Ok(decoded_data)
      False ->
        Error([
          DecodeError(
            message: message,
            error_kind: StringMinLenError(
              min_length: min_len,
              current_length: current_length,
            ),
            path: [],
          ),
        ])
    }
  }
}

pub fn string_min_len(source: Decoder(String), min_len: Int) -> Decoder(String) {
  string_min_len_with_message(
    source,
    min_len,
    "String is too short. Min length is " <> int.to_string(min_len),
  )
}

pub fn string_max_len_with_message(
  source: Decoder(String),
  max_len: Int,
  message: String,
) -> Decoder(String) {
  fn(data) {
    use decoded_data <- result.try(source(data))

    let current_length = string.length(decoded_data)
    let is_in_limit = current_length <= max_len

    case is_in_limit {
      True -> Ok(decoded_data)
      False ->
        Error([
          DecodeError(
            message: message,
            error_kind: StringMaxLenError(
              max_length: max_len,
              current_length: current_length,
            ),
            path: [],
          ),
        ])
    }
  }
}

pub fn string_max_len(source: Decoder(String), max_len: Int) -> Decoder(String) {
  string_max_len_with_message(
    source,
    max_len,
    "String is too long. Max length is " <> int.to_string(max_len),
  )
}

pub fn dict(
  key_decoder: Decoder(key),
  value_decoder: Decoder(value),
) -> Decoder(dict.Dict(key, value)) {
  fn(data) {
    use decoded <- result.try(
      dynamic.dict(dynamic.dynamic, dynamic.dynamic)(data)
      |> result.replace_error([
        DecodeError(
          message: "Expected type Dict",
          error_kind: TypeMismatch(
            expected: "Dict",
            found: dynamic.classify(data),
          ),
          path: [],
        ),
      ]),
    )

    use pairs <- result.try(
      decoded
      |> dict.to_list
      |> list.try_map(fn(pair) {
        let #(key, value) = pair

        use decoded_key <- result.try(
          key_decoder(key)
          |> map_errors(push_path(_, "[key]")),
        )

        use decoded_value <- result.try(
          value_decoder(value)
          |> map_errors(push_path(_, "[value]")),
        )

        Ok(#(decoded_key, decoded_value))
      }),
    )

    Ok(dict.from_list(pairs))
  }
}

pub fn dynamic(value: dynamic.Dynamic) -> DecodeResult(dynamic.Dynamic) {
  Ok(value)
}

pub fn field(
  name: String,
  inner_decoder: Decoder(inner_type),
) -> Decoder(inner_type) {
  fn(data) {
    use map <- result.try(dict(string, dynamic)(data))

    let maybe_field_value = dict.get(map, name)
    case maybe_field_value {
      Ok(field_value) ->
        inner_decoder(field_value)
        |> map_errors(push_path(_, name))
      Error(_) ->
        Error([
          DecodeError(
            message: "Field '" <> name <> "' not found",
            error_kind: FieldNotFound,
            path: [],
          ),
        ])
    }
  }
}

pub fn string_enum_with_message(
  source: Decoder(String),
  definition: List(#(String, output)),
  message: String,
) -> Decoder(output) {
  fn(data) {
    use source_value <- result.try(source(data))

    let maybe_enum_value =
      definition
      |> list.key_find(source_value)

    case maybe_enum_value {
      Ok(enum_value) -> Ok(enum_value)
      Error(_) -> {
        let available_keys =
          list.map(definition, fn(definition_pair) { definition_pair.0 })

        Error([
          DecodeError(
            message,
            error_kind: NotInStringEnum(
              available_keys: available_keys,
              found: source_value,
            ),
            path: [],
          ),
        ])
      }
    }
  }
}

pub fn string_enum(
  source: Decoder(String),
  definition: List(#(String, output)),
) -> Decoder(output) {
  string_enum_with_message(source, definition, "Expected String enum")
}

pub fn replace(
  source: Decoder(original_type),
  replace_value: new_type,
) -> Decoder(new_type) {
  fn(data) {
    use _ <- result.map(source(data))

    replace_value
  }
}

pub fn map(
  source: Decoder(original_type),
  mapper: fn(original_type) -> new_type,
) -> Decoder(new_type) {
  fn(data) {
    use decoded_data <- result.map(source(data))

    mapper(decoded_data)
  }
}

fn map_errors(
  result: DecodeResult(t),
  mapper: fn(DecodeError) -> DecodeError,
) -> DecodeResult(t) {
  result
  |> result.map_error(fn(errors) {
    errors
    |> list.map(mapper)
  })
}

fn push_path(error: DecodeError, path_segment: String) -> DecodeError {
  DecodeError(..error, path: [path_segment, ..error.path])
}

fn create_basic_decoder(
  message: String,
  expected: String,
  decoder: dynamic.Decoder(t),
) -> Decoder(t) {
  fn(data) {
    case decoder(data) {
      Ok(decoded_value) -> Ok(decoded_value)
      Error(_) ->
        Error([
          DecodeError(
            message: message,
            error_kind: TypeMismatch(
              expected: expected,
              found: dynamic.classify(data),
            ),
            path: [],
          ),
        ])
    }
  }
}

fn create_literal_decoder(
  message: String,
  expected_value: t,
  trust_type_constructor: fn(t) -> String,
  decoder: dynamic.Decoder(t),
) -> Decoder(t) {
  fn(data) {
    case decoder(data) {
      Ok(decoded_value) if decoded_value == expected_value -> Ok(decoded_value)
      Ok(decoded_value) ->
        Error([
          DecodeError(
            message: message,
            error_kind: TypeMismatch(
              expected: trust_type_constructor(expected_value),
              found: trust_type_constructor(decoded_value),
            ),
            path: [],
          ),
        ])
      Error(_) ->
        Error([
          DecodeError(
            message: message,
            error_kind: TypeMismatch(
              expected: trust_type_constructor(expected_value),
              found: dynamic.classify(data),
            ),
            path: [],
          ),
        ])
    }
  }
}
