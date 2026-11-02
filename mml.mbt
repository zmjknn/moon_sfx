///|
/// Pure MoonBit Music Macro Language (MML) Parser and Melody Compiler.
/// Supports classic retro game MML syntax (e.g. "T140 O4 C8 E8 G8 > C4").

///|
/// Helper to extract Char at index from String.
fn char_at(s : String, idx : Int) -> Char {
  s[idx].to_int().unsafe_to_char()
}

///|
/// Parses an unsigned integer from a string starting at index `start`.
/// Returns a tuple of (parsed_value, next_index).
fn parse_int_digits(s : String, start : Int) -> (Int, Int) {
  let mut val = 0
  let mut idx = start
  let mut found = false
  while idx < s.length() {
    let c = char_at(s, idx)
    if c >= '0' && c <= '9' {
      let digit = c.to_int() - '0'.to_int()
      val = val * 10 + digit
      idx = idx + 1
      found = true
    } else {
      break
    }
  }
  if found {
    (val, idx)
  } else {
    (0, start)
  }
}

///|
/// Maps a numeric duration value (1, 2, 4, 8, 16) to the Duration enum.
fn number_to_duration(num : Int, default_dur : Duration) -> Duration {
  match num {
    1 => Whole
    2 => Half
    4 => Quarter
    8 => Eighth
    16 => Sixteenth
    _ => default_dur
  }
}

///|
/// Parses note pitch class from note letter and accidental ('#' / '+' / '-').
fn parse_pitch(letter : Char, accidental : Char) -> Note {
  match letter {
    'C' | 'c' => if accidental == '#' || accidental == '+' { Cs } else { C }
    'D' | 'd' => if accidental == '#' || accidental == '+' { Ds } else if accidental == '-' { Cs } else { D }
    'E' | 'e' => if accidental == '-' { Ds } else { E }
    'F' | 'f' => if accidental == '#' || accidental == '+' { Fs } else { F }
    'G' | 'g' => if accidental == '#' || accidental == '+' { Gs } else if accidental == '-' { Fs } else { G }
    'A' | 'a' => if accidental == '#' || accidental == '+' { As } else if accidental == '-' { Gs } else { A }
    'B' | 'b' => if accidental == '-' { As } else { B }
    _ => Rest
  }
}

///|
/// Parses an MML string into a Score and tempo BPM.
///
/// Supported MML Syntax:
/// - `T<bpm>`: Sets playback tempo (e.g. `T140`). Default: 120.
/// - `O<octave>`: Sets octave 1..7 (e.g. `O4`). Default: 4.
/// - `>`: Octave up by 1.
/// - `<`: Octave down by 1.
/// - `L<length>`: Sets default note duration: 1 (Whole), 2 (Half), 4 (Quarter), 8 (Eighth), 16 (Sixteenth). Default: 4.
/// - `V<volume>`: Sets volume 0..100 (e.g. `V80` -> 0.8). Default: 80.
/// - Notes `C, D, E, F, G, A, B`:
///   - Optional accidentals: `#` or `+` (sharp), `-` (flat)
///   - Optional explicit duration: e.g. `C8`, `F#16`, `D-2`, `A1`
/// - Rests: `R` or `P` with optional duration (e.g. `R4`, `R8`).
/// - Whitespace and bar dividers `|`, `,`, `;` are ignored.
pub fn parse_mml(mml : String) -> (Score, Int) {
  let score = Score::new()
  let len = mml.length()

  let mut bpm = 120
  let mut octave = 4
  let mut default_dur = Duration::Quarter
  let mut volume = 0.8

  let mut i = 0
  while i < len {
    let ch = char_at(mml, i)

    // Skip whitespace, separators, and bar lines
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == '|' || ch == ',' || ch == ';' {
      i = i + 1
      continue
    }

    match ch {
      // Tempo
      'T' | 't' => {
        let (val, next_i) = parse_int_digits(mml, i + 1)
        if val > 0 {
          bpm = val
        }
        i = next_i
      }

      // Octave
      'O' | 'o' => {
        let (val, next_i) = parse_int_digits(mml, i + 1)
        if val >= 1 && val <= 7 {
          octave = val
        }
        i = next_i
      }

      // Octave Up
      '>' => {
        octave = if octave < 7 { octave + 1 } else { 7 }
        i = i + 1
      }

      // Octave Down
      '<' => {
        octave = if octave > 1 { octave - 1 } else { 1 }
        i = i + 1
      }

      // Default Length
      'L' | 'l' => {
        let (val, next_i) = parse_int_digits(mml, i + 1)
        if val > 0 {
          default_dur = number_to_duration(val, default_dur)
        }
        i = next_i
      }

      // Volume (0..100)
      'V' | 'v' => {
        let (val, next_i) = parse_int_digits(mml, i + 1)
        if val >= 0 {
          let v = val.to_double() / 100.0
          volume = if v > 1.0 { 1.0 } else { v }
        }
        i = next_i
      }

      // Rest (Silence)
      'R' | 'r' | 'P' | 'p' => {
        let (val, next_i) = parse_int_digits(mml, i + 1)
        let dur = if val > 0 { number_to_duration(val, default_dur) } else { default_dur }
        score.add(Rest, octave, dur, 0.0)
        i = next_i
      }

      // Pitch Notes: C, D, E, F, G, A, B
      'C' | 'c' | 'D' | 'd' | 'E' | 'e' | 'F' | 'f' | 'G' | 'g' | 'A' | 'a' | 'B' | 'b' => {
        let mut accidental = ' '
        let mut cur_i = i + 1
        if cur_i < len {
          let next_ch = char_at(mml, cur_i)
          if next_ch == '#' || next_ch == '+' || next_ch == '-' {
            accidental = next_ch
            cur_i = cur_i + 1
          }
        }

        let (val, next_i) = parse_int_digits(mml, cur_i)
        let dur = if val > 0 { number_to_duration(val, default_dur) } else { default_dur }
        let pitch = parse_pitch(ch, accidental)
        score.add(pitch, octave, dur, volume)
        i = next_i
      }

      // Unknown character, skip
      _ => {
        i = i + 1
      }
    }
  }

  (score, bpm)
}

///|
/// Compiles an MML string directly into a rendered AudioBuffer.
pub fn render_mml(
  mml : String,
  waveform : Waveform,
  adsr : ADSR,
  sample_rate : Int
) -> AudioBuffer {
  let (score, bpm) = parse_mml(mml)
  render_score(score, bpm, waveform, adsr, sample_rate)
}