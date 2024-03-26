import gleam/dynamic
import gleam/dict
import gleeunit
import gleeunit/should
import trust

pub fn main() {
  gleeunit.main()
}

pub fn bool_with_message_test() {
  True
  |> dynamic.from
  |> trust.bool_with_message("msg")
  |> should.equal(Ok(True))

  False
  |> dynamic.from
  |> trust.bool_with_message("msg")
  |> should.equal(Ok(False))

  1
  |> dynamic.from
  |> trust.bool_with_message("msg")
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.TypeMismatch(expected: "Bool", found: "Int"),
        path: [],
      ),
    ]),
  )
}

pub fn bool_literal_with_message_test() {
  True
  |> dynamic.from
  |> trust.bool_literal_with_message(True, "msg")
  |> should.equal(Ok(True))

  False
  |> dynamic.from
  |> trust.bool_literal_with_message(True, "msg")
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.TypeMismatch(expected: "True", found: "False"),
        path: [],
      ),
    ]),
  )

  1
  |> dynamic.from
  |> trust.bool_literal_with_message(True, "msg")
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.TypeMismatch(expected: "True", found: "Int"),
        path: [],
      ),
    ]),
  )
}

pub fn string_with_message_test() {
  ""
  |> dynamic.from
  |> trust.string_with_message("msg")
  |> should.equal(Ok(""))

  "Hello"
  |> dynamic.from
  |> trust.string_with_message("msg")
  |> should.equal(Ok("Hello"))

  1
  |> dynamic.from
  |> trust.string_with_message("msg")
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.TypeMismatch(expected: "String", found: "Int"),
        path: [],
      ),
    ]),
  )
}

pub fn string_literal_with_message_test() {
  "A"
  |> dynamic.from
  |> trust.string_literal_with_message("A", "msg")
  |> should.equal(Ok("A"))

  "B"
  |> dynamic.from
  |> trust.string_literal_with_message("A", "msg")
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.TypeMismatch(expected: "\"A\"", found: "\"B\""),
        path: [],
      ),
    ]),
  )

  1
  |> dynamic.from
  |> trust.string_literal_with_message("A", "msg")
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.TypeMismatch(expected: "\"A\"", found: "Int"),
        path: [],
      ),
    ]),
  )
}

pub fn string_len_with_message_test() {
  "123"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_len_with_message(3, "msg")
  }
  |> should.equal(Ok("123"))

  "123"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_len_with_message(2, "msg")
  }
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.StringLenError(expected_length: 2, current_length: 3),
        path: [],
      ),
    ]),
  )

  "123"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_len_with_message(4, "msg")
  }
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.StringLenError(expected_length: 4, current_length: 3),
        path: [],
      ),
    ]),
  )
}

pub fn string_min_len_with_message_test() {
  "123"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_min_len_with_message(2, "msg")
  }
  |> should.equal(Ok("123"))

  "123"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_min_len_with_message(3, "msg")
  }
  |> should.equal(Ok("123"))

  "123"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_min_len_with_message(4, "msg")
  }
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.StringMinLenError(min_length: 4, current_length: 3),
        path: [],
      ),
    ]),
  )
}

pub fn string_max_len_with_message_test() {
  "123"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_max_len_with_message(4, "msg")
  }
  |> should.equal(Ok("123"))

  "123"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_max_len_with_message(3, "msg")
  }
  |> should.equal(Ok("123"))

  "123"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_max_len_with_message(2, "msg")
  }
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.StringMaxLenError(max_length: 2, current_length: 3),
        path: [],
      ),
    ]),
  )
}

pub fn dict_test() {
  dict.new()
  |> dict.insert("A", "A")
  |> dict.insert("B", "B")
  |> dynamic.from()
  |> trust.dict(trust.string, trust.string)
  |> should.equal(
    dict.new()
    |> dict.insert("A", "A")
    |> dict.insert("B", "B")
    |> Ok,
  )

  1
  |> dynamic.from()
  |> trust.dict(trust.string, trust.string)
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "Expected type Dict",
        error_kind: trust.TypeMismatch(expected: "Dict", found: "Int"),
        path: [],
      ),
    ]),
  )

  dict.new()
  |> dict.insert("A", "A")
  |> dict.insert("B", "B")
  |> dynamic.from()
  |> trust.dict(trust.bool, trust.string)
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "Expected type Bool",
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        path: ["[key]"],
      ),
    ]),
  )

  dict.new()
  |> dict.insert("A", "A")
  |> dict.insert("B", "B")
  |> dynamic.from()
  |> trust.dict(trust.string, trust.bool)
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "Expected type Bool",
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        path: ["[value]"],
      ),
    ]),
  )

  dict.new()
  |> dynamic.from()
  |> trust.dict(trust.string, trust.string)
  |> should.equal(Ok(dict.from_list([])))
}

pub fn field_test() {
  dict.new()
  |> dict.insert("A", "A")
  |> dict.insert("B", "B")
  |> dynamic.from()
  |> trust.field("A", trust.string)
  |> should.equal(Ok("A"))

  dict.new()
  |> dict.insert("A", "A")
  |> dict.insert("B", "B")
  |> dynamic.from()
  |> trust.field("B", trust.string)
  |> should.equal(Ok("B"))

  dict.new()
  |> dict.insert("A", "A")
  |> dict.insert("B", "B")
  |> dynamic.from()
  |> trust.field("A", trust.bool)
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "Expected type Bool",
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        path: ["A"],
      ),
    ]),
  )

  dict.new()
  |> dict.insert("A", "A")
  |> dict.insert("B", "B")
  |> dynamic.from()
  |> trust.field("C", trust.string)
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "Field 'C' not found",
        error_kind: trust.FieldNotFound,
        path: [],
      ),
    ]),
  )

  1
  |> dynamic.from()
  |> trust.field("C", trust.string)
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "Expected type Dict",
        error_kind: trust.TypeMismatch(expected: "Dict", found: "Int"),
        path: [],
      ),
    ]),
  )
}

pub fn string_map_enum_with_message_test() {
  "A"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_enum_with_message([#("A", 0), #("B", 1)], "msg")
  }
  |> should.equal(Ok(0))

  "B"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_enum_with_message([#("A", 0), #("B", 1)], "msg")
  }
  |> should.equal(Ok(1))

  "C"
  |> dynamic.from
  |> {
    trust.string
    |> trust.string_enum_with_message([#("A", 0), #("B", 1)], "msg")
  }
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "msg",
        error_kind: trust.NotInStringEnum(
          available_keys: ["A", "B"],
          found: "C",
        ),
        path: [],
      ),
    ]),
  )
}

pub fn replace_test() {
  ""
  |> dynamic.from
  |> {
    trust.string
    |> trust.replace(1)
  }
  |> should.equal(Ok(1))

  Nil
  |> dynamic.from
  |> {
    trust.string
    |> trust.replace(1)
  }
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "Expected type String",
        error_kind: trust.TypeMismatch(expected: "String", found: "Nil"),
        path: [],
      ),
    ]),
  )
}

pub fn map_test() {
  "is awesome"
  |> dynamic.from
  |> {
    trust.string
    |> trust.map(fn(value) { "Gleam " <> value })
  }
  |> should.equal(Ok("Gleam is awesome"))

  Nil
  |> dynamic.from
  |> {
    trust.string
    |> trust.map(fn(value) { "Gleam " <> value })
  }
  |> should.equal(
    Error([
      trust.DecodeError(
        message: "Expected type String",
        error_kind: trust.TypeMismatch(expected: "String", found: "Nil"),
        path: [],
      ),
    ]),
  )
}
