import gleam/dynamic
import gleam/dict
import gleam/string
import gleam/list
import gleam/int
import gleam/result
import gleam/bool

pub type DecodeErrorKind {
  TypeMismatch(expected: String, found: String)
  IntMinError(min: Int, actual: Int)
  IntMaxError(max: Int, actual: Int)
  FieldNotFound
  NotInStringEnum(available_keys: List(String), found: String)
  StringLenError(expected_length: Int, actual_length: Int)
  StringMinLenError(min_length: Int, actual_length: Int)
  StringMaxLenError(max_length: Int, actual_length: Int)
  TupleNegativeIndex(index: Int)
  TupleTooSmall(required_size: Int, actual_size: Int)
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

pub fn int_with_message(message: String) -> Decoder(Int) {
  create_basic_decoder(message, "Int", dynamic.int)
}

pub fn int(data: dynamic.Dynamic) -> DecodeResult(Int) {
  int_with_message("Expected type Int")(data)
}

pub fn int_literal_with_message(value: Int, message: String) -> Decoder(Int) {
  create_literal_decoder(message, value, int.to_string, dynamic.int)
}

pub fn int_literal(value: Int) -> Decoder(Int) {
  int_literal_with_message(value, "Expected " <> int.to_string(value))
}

pub fn int_min_with_message(
  source: Decoder(Int),
  min: Int,
  message: String,
) -> Decoder(Int) {
  fn(data) {
    use decoded <- result.try(source(data))

    case decoded >= min {
      True -> Ok(decoded)
      False ->
        Error([
          DecodeError(
            message: message,
            error_kind: IntMinError(min: min, actual: decoded),
            path: [],
          ),
        ])
    }
  }
}

pub fn int_min(source: Decoder(Int), min: Int) -> Decoder(Int) {
  int_min_with_message(
    source,
    min,
    "Int is too small. Min is " <> int.to_string(min),
  )
}

pub fn int_max_with_message(
  source: Decoder(Int),
  max: Int,
  message: String,
) -> Decoder(Int) {
  fn(data) {
    use decoded <- result.try(source(data))

    case decoded <= max {
      True -> Ok(decoded)
      False ->
        Error([
          DecodeError(
            message: message,
            error_kind: IntMaxError(max: max, actual: decoded),
            path: [],
          ),
        ])
    }
  }
}

pub fn int_max(source: Decoder(Int), max: Int) -> Decoder(Int) {
  int_max_with_message(
    source,
    max,
    "Int too large. Max is " <> int.to_string(max),
  )
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

    let actual_length = string.length(decoded_data)
    let is_in_limit = actual_length == len

    case is_in_limit {
      True -> Ok(decoded_data)
      False ->
        Error([
          DecodeError(
            message: message,
            error_kind: StringLenError(
              expected_length: len,
              actual_length: actual_length,
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

    let actual_length = string.length(decoded_data)
    let is_in_limit = actual_length >= min_len

    case is_in_limit {
      True -> Ok(decoded_data)
      False ->
        Error([
          DecodeError(
            message: message,
            error_kind: StringMinLenError(
              min_length: min_len,
              actual_length: actual_length,
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

    let actual_length = string.length(decoded_data)
    let is_in_limit = actual_length <= max_len

    case is_in_limit {
      True -> Ok(decoded_data)
      False ->
        Error([
          DecodeError(
            message: message,
            error_kind: StringMaxLenError(
              max_length: max_len,
              actual_length: actual_length,
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

pub fn element_with_message(
  index: Int,
  inner_decoder: Decoder(inner_type),
  message: String,
) -> Decoder(inner_type) {
  fn(data) {
    use _ <- result.try(case index < 0 {
      True ->
        Error([
          DecodeError(
            error_kind: TupleNegativeIndex(index: index),
            message: message,
            path: [],
          ),
        ])
      False -> Ok(Nil)
    })

    use tuple <- result.try(
      decode_tuple(data)
      |> result.replace_error([
        DecodeError(
          error_kind: TypeMismatch(
            expected: "Tuple",
            found: dynamic.classify(data),
          ),
          message: message,
          path: [],
        ),
      ]),
    )

    use element <- result.try(
      tuple_get(tuple, index)
      |> result.replace_error([
        DecodeError(
          error_kind: TupleTooSmall(
            required_size: index + 1,
            actual_size: tuple_size(tuple),
          ),
          message: message,
          path: [],
        ),
      ]),
    )

    inner_decoder(element)
  }
}

// A tuple of unknown size
type UnknownTuple

@external(erlang, "gleam_stdlib", "decode_tuple")
@external(javascript, "../gleam_stdlib/gleam_stdlib.mjs", "decode_tuple")
fn decode_tuple(
  data: dynamic.Dynamic,
) -> Result(UnknownTuple, dynamic.DecodeErrors)

@external(erlang, "gleam_stdlib", "tuple_get")
@external(javascript, "../gleam_stdlib/gleam_stdlib.mjs", "tuple_get")
fn tuple_get(
  a: UnknownTuple,
  b: Int,
) -> Result(dynamic.Dynamic, dynamic.DecodeErrors)

@external(erlang, "gleam_stdlib", "size_of_tuple")
@external(javascript, "../gleam_stdlib/gleam_stdlib.mjs", "length")
fn tuple_size(a: UnknownTuple) -> Int

pub fn element(
  index: Int,
  inner_decoder: Decoder(inner_type),
) -> Decoder(inner_type) {
  element_with_message(
    index,
    inner_decoder,
    "Expected tuple of size at least " <> int.to_string(index + 1),
  )
}

pub fn decode1(constructor: fn(t1) -> t, t1: Decoder(t1)) -> Decoder(t) {
  fn(value) {
    case t1(value) {
      Ok(a) -> Ok(constructor(a))
      a -> Error(all_errors(a))
    }
  }
}

pub fn decode2(
  constructor: fn(t1, t2) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
) -> Decoder(t) {
  fn(value) {
    case t1(value), t2(value) {
      Ok(a), Ok(b) -> Ok(constructor(a, b))
      a, b -> Error(list.concat([all_errors(a), all_errors(b)]))
    }
  }
}

pub fn decode3(
  constructor: fn(t1, t2, t3) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
) -> Decoder(t) {
  fn(value) {
    case t1(value), t2(value), t3(value) {
      Ok(a), Ok(b), Ok(c) -> Ok(constructor(a, b, c))
      a, b, c ->
        Error(list.concat([all_errors(a), all_errors(b), all_errors(c)]))
    }
  }
}

pub fn decode4(
  constructor: fn(t1, t2, t3, t4) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
  t4: Decoder(t4),
) -> Decoder(t) {
  fn(data) {
    case t1(data), t2(data), t3(data), t4(data) {
      Ok(a), Ok(b), Ok(c), Ok(d) -> Ok(constructor(a, b, c, d))
      a, b, c, d ->
        Error(
          list.concat([
            all_errors(a),
            all_errors(b),
            all_errors(c),
            all_errors(d),
          ]),
        )
    }
  }
}

pub fn decode5(
  constructor: fn(t1, t2, t3, t4, t5) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
  t4: Decoder(t4),
  t5: Decoder(t5),
) -> Decoder(t) {
  fn(data) {
    case t1(data), t2(data), t3(data), t4(data), t5(data) {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e) -> Ok(constructor(a, b, c, d, e))
      a, b, c, d, e ->
        Error(
          list.concat([
            all_errors(a),
            all_errors(b),
            all_errors(c),
            all_errors(d),
            all_errors(e),
          ]),
        )
    }
  }
}

pub fn decode6(
  constructor: fn(t1, t2, t3, t4, t5, t6) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
  t4: Decoder(t4),
  t5: Decoder(t5),
  t6: Decoder(t6),
) -> Decoder(t) {
  fn(data) {
    case t1(data), t2(data), t3(data), t4(data), t5(data), t6(data) {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f) ->
        Ok(constructor(a, b, c, d, e, f))
      a, b, c, d, e, f ->
        Error(
          list.concat([
            all_errors(a),
            all_errors(b),
            all_errors(c),
            all_errors(d),
            all_errors(e),
            all_errors(f),
          ]),
        )
    }
  }
}

pub fn decode7(
  constructor: fn(t1, t2, t3, t4, t5, t6, t7) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
  t4: Decoder(t4),
  t5: Decoder(t5),
  t6: Decoder(t6),
  t7: Decoder(t7),
) -> Decoder(t) {
  fn(data) {
    case t1(data), t2(data), t3(data), t4(data), t5(data), t6(data), t7(data) {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f), Ok(g) ->
        Ok(constructor(a, b, c, d, e, f, g))
      a, b, c, d, e, f, g ->
        Error(
          list.concat([
            all_errors(a),
            all_errors(b),
            all_errors(c),
            all_errors(d),
            all_errors(e),
            all_errors(f),
            all_errors(g),
          ]),
        )
    }
  }
}

pub fn decode8(
  constructor: fn(t1, t2, t3, t4, t5, t6, t7, t8) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
  t4: Decoder(t4),
  t5: Decoder(t5),
  t6: Decoder(t6),
  t7: Decoder(t7),
  t8: Decoder(t8),
) -> Decoder(t) {
  fn(data) {
    case
      t1(data),
      t2(data),
      t3(data),
      t4(data),
      t5(data),
      t6(data),
      t7(data),
      t8(data)
    {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f), Ok(g), Ok(h) ->
        Ok(constructor(a, b, c, d, e, f, g, h))
      a, b, c, d, e, f, g, h ->
        Error(
          list.concat([
            all_errors(a),
            all_errors(b),
            all_errors(c),
            all_errors(d),
            all_errors(e),
            all_errors(f),
            all_errors(g),
            all_errors(h),
          ]),
        )
    }
  }
}

pub fn decode9(
  constructor: fn(t1, t2, t3, t4, t5, t6, t7, t8, t9) -> t,
  t1: Decoder(t1),
  t2: Decoder(t2),
  t3: Decoder(t3),
  t4: Decoder(t4),
  t5: Decoder(t5),
  t6: Decoder(t6),
  t7: Decoder(t7),
  t8: Decoder(t8),
  t9: Decoder(t9),
) -> Decoder(t) {
  fn(data) {
    case
      t1(data),
      t2(data),
      t3(data),
      t4(data),
      t5(data),
      t6(data),
      t7(data),
      t8(data),
      t9(data)
    {
      Ok(a), Ok(b), Ok(c), Ok(d), Ok(e), Ok(f), Ok(g), Ok(h), Ok(i) ->
        Ok(constructor(a, b, c, d, e, f, g, h, i))
      a, b, c, d, e, f, g, h, i ->
        Error(
          list.concat([
            all_errors(a),
            all_errors(b),
            all_errors(c),
            all_errors(d),
            all_errors(e),
            all_errors(f),
            all_errors(g),
            all_errors(h),
            all_errors(i),
          ]),
        )
    }
  }
}

fn all_errors(result: Result(a, List(DecodeError))) -> List(DecodeError) {
  case result {
    Ok(_) -> []
    Error(errors) -> errors
  }
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
