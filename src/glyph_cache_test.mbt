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
test "subpixel bins (ported from cosmic-text)" {
  // POSITIVE
  inspect(SubpixelBin::new(0.0F), content="(0, Zero)")
  inspect(SubpixelBin::new(0.124F), content="(0, Zero)")
  inspect(SubpixelBin::new(0.125F), content="(0, One)")
  inspect(SubpixelBin::new(0.25F), content="(0, One)")
  inspect(SubpixelBin::new(0.374F), content="(0, One)")
  inspect(SubpixelBin::new(0.375F), content="(0, Two)")
  inspect(SubpixelBin::new(0.5F), content="(0, Two)")
  inspect(SubpixelBin::new(0.624F), content="(0, Two)")
  inspect(SubpixelBin::new(0.625F), content="(0, Three)")
  inspect(SubpixelBin::new(0.75F), content="(0, Three)")
  inspect(SubpixelBin::new(0.874F), content="(0, Three)")
  inspect(SubpixelBin::new(0.875F), content="(1, Zero)")
  inspect(SubpixelBin::new(0.999F), content="(1, Zero)")
  inspect(SubpixelBin::new(1.0F), content="(1, Zero)")
  inspect(SubpixelBin::new(1.124F), content="(1, Zero)")

  // NEGATIVE
  inspect(SubpixelBin::new(-0.0F), content="(0, Zero)")
  inspect(SubpixelBin::new(-0.124F), content="(0, Zero)")
  inspect(SubpixelBin::new(-0.125F), content="(-1, Three)")
  inspect(SubpixelBin::new(-0.25F), content="(-1, Three)")
  inspect(SubpixelBin::new(-0.374F), content="(-1, Three)")
  inspect(SubpixelBin::new(-0.375F), content="(-1, Two)")
  inspect(SubpixelBin::new(-0.5F), content="(-1, Two)")
  inspect(SubpixelBin::new(-0.624F), content="(-1, Two)")
  inspect(SubpixelBin::new(-0.625F), content="(-1, One)")
  inspect(SubpixelBin::new(-0.75F), content="(-1, One)")
  inspect(SubpixelBin::new(-0.874F), content="(-1, One)")
  inspect(SubpixelBin::new(-0.875F), content="(-1, Zero)")
  inspect(SubpixelBin::new(-0.999F), content="(-1, Zero)")
  inspect(SubpixelBin::new(-1.0F), content="(-1, Zero)")
  inspect(SubpixelBin::new(-1.124F), content="(-1, Zero)")
}
