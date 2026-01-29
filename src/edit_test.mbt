// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
test "Change.reverse reverses items and flips insert/delete" {
  let a = ChangeItem::{
    start: Cursor::new(0, 0),
    end: Cursor::new(0, 1),
    text: "x",
    insert: true,
  }
  let b = ChangeItem::{
    start: Cursor::new(1, 0),
    end: Cursor::new(1, 2),
    text: "yy",
    insert: false,
  }
  let change = Change::{ items: [a, b] }
  let rev = change.reverse()
  inspect(rev.items.length(), content="2")
  inspect(rev.items[0].text, content="yy")
  inspect(rev.items[0].insert, content="true")
  inspect(rev.items[1].text, content="x")
  inspect(rev.items[1].insert, content="false")
}
