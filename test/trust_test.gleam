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
        error_kind: trust.StringLenError(expected_length: 2, actual_length: 3),
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
        error_kind: trust.StringLenError(expected_length: 4, actual_length: 3),
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
        error_kind: trust.StringMinLenError(min_length: 4, actual_length: 3),
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
        error_kind: trust.StringMaxLenError(max_length: 2, actual_length: 3),
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

pub fn element_test() {
  #("a", True)
  |> dynamic.from
  |> trust.element_with_message(0, trust.string, "msg")
  |> should.equal(Ok("a"))

  #("a", True)
  |> dynamic.from
  |> trust.element_with_message(1, trust.bool, "msg")
  |> should.equal(Ok(True))

  #("a", True)
  |> dynamic.from
  |> trust.element_with_message(-1, trust.bool, "msg")
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TupleNegativeIndex(index: -1),
        message: "msg",
        path: [],
      ),
    ]),
  )

  #("a", True)
  |> dynamic.from
  |> trust.element_with_message(2, trust.bool, "msg")
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TupleTooSmall(required_size: 3, actual_size: 2),
        message: "msg",
        path: [],
      ),
    ]),
  )

  #("a", True)
  |> dynamic.from
  |> trust.element_with_message(0, trust.bool_with_message("bool msg"), "msg")
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        message: "bool msg",
        path: [],
      ),
    ]),
  )

  #("a", True)
  |> dynamic.from
  |> trust.element_with_message(
    1,
    trust.string_with_message("string msg"),
    "msg",
  )
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "String", found: "Atom"),
        message: "string msg",
        path: [],
      ),
    ]),
  )
}

pub fn decode1_test() {
  let decoder =
    trust.decode1(
      fn(a) { #(a) },
      trust.element(0, trust.bool_with_message("msg")),
    )

  #(True)
  |> dynamic.from
  |> decoder
  |> should.equal(Ok(#(True)))

  #(1)
  |> dynamic.from
  |> decoder
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "Int"),
        message: "msg",
        path: [],
      ),
    ]),
  )
}

pub fn decode2_test() {
  let decoder =
    trust.decode2(
      fn(a, b) { #(a, b) },
      trust.element(0, trust.bool_with_message("msg_0")),
      trust.element(1, trust.string_with_message("msg_1")),
    )

  #(True, "a")
  |> dynamic.from
  |> decoder
  |> should.equal(Ok(#(True, "a")))

  #("a", True)
  |> dynamic.from
  |> decoder
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        message: "msg_0",
        path: [],
      ),
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "String", found: "Atom"),
        message: "msg_1",
        path: [],
      ),
    ]),
  )
}

pub fn decode3_test() {
  let decoder =
    trust.decode3(
      fn(a, b, c) { #(a, b, c) },
      trust.element(0, trust.bool_with_message("msg_0")),
      trust.element(1, trust.string_with_message("msg_1")),
      trust.element(2, trust.bool_with_message("msg_2")),
    )

  #(True, "a", False)
  |> dynamic.from
  |> decoder
  |> should.equal(Ok(#(True, "a", False)))

  #("a", True, False)
  |> dynamic.from
  |> decoder
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        message: "msg_0",
        path: [],
      ),
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "String", found: "Atom"),
        message: "msg_1",
        path: [],
      ),
    ]),
  )
}

pub fn decode4_test() {
  let decoder =
    trust.decode4(
      fn(a, b, c, d) { #(a, b, c, d) },
      trust.element(0, trust.bool_with_message("msg_0")),
      trust.element(1, trust.string_with_message("msg_1")),
      trust.element(2, trust.bool_with_message("msg_2")),
      trust.element(3, trust.string_with_message("msg_3")),
    )

  #(True, "a", False, "b")
  |> dynamic.from
  |> decoder
  |> should.equal(Ok(#(True, "a", False, "b")))

  #("a", True, False, "b")
  |> dynamic.from
  |> decoder
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        message: "msg_0",
        path: [],
      ),
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "String", found: "Atom"),
        message: "msg_1",
        path: [],
      ),
    ]),
  )
}

pub fn decode5_test() {
  let decoder =
    trust.decode5(
      fn(a, b, c, d, e) { #(a, b, c, d, e) },
      trust.element(0, trust.bool_with_message("msg_0")),
      trust.element(1, trust.string_with_message("msg_1")),
      trust.element(2, trust.bool_with_message("msg_2")),
      trust.element(3, trust.string_with_message("msg_3")),
      trust.element(4, trust.bool_with_message("msg_4")),
    )

  #(True, "a", False, "b", True)
  |> dynamic.from
  |> decoder
  |> should.equal(Ok(#(True, "a", False, "b", True)))

  #("a", True, False, "b", True)
  |> dynamic.from
  |> decoder
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        message: "msg_0",
        path: [],
      ),
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "String", found: "Atom"),
        message: "msg_1",
        path: [],
      ),
    ]),
  )
}

pub fn decode6_test() {
  let decoder =
    trust.decode6(
      fn(a, b, c, d, e, f) { #(a, b, c, d, e, f) },
      trust.element(0, trust.bool_with_message("msg_0")),
      trust.element(1, trust.string_with_message("msg_1")),
      trust.element(2, trust.bool_with_message("msg_2")),
      trust.element(3, trust.string_with_message("msg_3")),
      trust.element(4, trust.bool_with_message("msg_4")),
      trust.element(5, trust.string_with_message("msg_5")),
    )

  #(True, "a", False, "b", True, "c")
  |> dynamic.from
  |> decoder
  |> should.equal(Ok(#(True, "a", False, "b", True, "c")))

  #("a", True, False, "b", True, "c")
  |> dynamic.from
  |> decoder
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        message: "msg_0",
        path: [],
      ),
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "String", found: "Atom"),
        message: "msg_1",
        path: [],
      ),
    ]),
  )
}

pub fn decode7_test() {
  let decoder =
    trust.decode7(
      fn(a, b, c, d, e, f, g) { #(a, b, c, d, e, f, g) },
      trust.element(0, trust.bool_with_message("msg_0")),
      trust.element(1, trust.string_with_message("msg_1")),
      trust.element(2, trust.bool_with_message("msg_2")),
      trust.element(3, trust.string_with_message("msg_3")),
      trust.element(4, trust.bool_with_message("msg_4")),
      trust.element(5, trust.string_with_message("msg_5")),
      trust.element(6, trust.bool_with_message("msg_6")),
    )

  #(True, "a", False, "b", True, "c", False)
  |> dynamic.from
  |> decoder
  |> should.equal(Ok(#(True, "a", False, "b", True, "c", False)))

  #("a", True, False, "b", True, "c", False)
  |> dynamic.from
  |> decoder
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        message: "msg_0",
        path: [],
      ),
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "String", found: "Atom"),
        message: "msg_1",
        path: [],
      ),
    ]),
  )
}

pub fn decode8_test() {
  let decoder =
    trust.decode8(
      fn(a, b, c, d, e, f, g, h) { #(a, b, c, d, e, f, g, h) },
      trust.element(0, trust.bool_with_message("msg_0")),
      trust.element(1, trust.string_with_message("msg_1")),
      trust.element(2, trust.bool_with_message("msg_2")),
      trust.element(3, trust.string_with_message("msg_3")),
      trust.element(4, trust.bool_with_message("msg_4")),
      trust.element(5, trust.string_with_message("msg_5")),
      trust.element(6, trust.bool_with_message("msg_6")),
      trust.element(7, trust.string_with_message("msg_7")),
    )

  #(True, "a", False, "b", True, "c", False, "d")
  |> dynamic.from
  |> decoder
  |> should.equal(Ok(#(True, "a", False, "b", True, "c", False, "d")))

  #("a", True, False, "b", True, "c", False, "d")
  |> dynamic.from
  |> decoder
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        message: "msg_0",
        path: [],
      ),
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "String", found: "Atom"),
        message: "msg_1",
        path: [],
      ),
    ]),
  )
}

pub fn decode9_test() {
  let decoder =
    trust.decode9(
      fn(a, b, c, d, e, f, g, h, i) { #(a, b, c, d, e, f, g, h, i) },
      trust.element(0, trust.bool_with_message("msg_0")),
      trust.element(1, trust.string_with_message("msg_1")),
      trust.element(2, trust.bool_with_message("msg_2")),
      trust.element(3, trust.string_with_message("msg_3")),
      trust.element(4, trust.bool_with_message("msg_4")),
      trust.element(5, trust.string_with_message("msg_5")),
      trust.element(6, trust.bool_with_message("msg_6")),
      trust.element(7, trust.string_with_message("msg_7")),
      trust.element(8, trust.bool_with_message("msg_8")),
    )

  #(True, "a", False, "b", True, "c", False, "d", True)
  |> dynamic.from
  |> decoder
  |> should.equal(Ok(#(True, "a", False, "b", True, "c", False, "d", True)))

  #("a", True, False, "b", True, "c", False, "d", True)
  |> dynamic.from
  |> decoder
  |> should.equal(
    Error([
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "Bool", found: "String"),
        message: "msg_0",
        path: [],
      ),
      trust.DecodeError(
        error_kind: trust.TypeMismatch(expected: "String", found: "Atom"),
        message: "msg_1",
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
