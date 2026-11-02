///|
/// Semitone musical pitch class in standard 12-tone equal temperament.
pub(all) enum Note {
  C
  Cs // C# / Db
  D
  Ds // D# / Eb
  E
  F
  Fs // F# / Gb
  G
  Gs // G# / Ab
  A
  As // A# / Bb
  B
  Rest // Silence
} derive(Eq, Debug)

///|
/// Musical note duration relative to measure meter.
pub(all) enum Duration {
  Whole // 4 beats
  Half // 2 beats
  Quarter // 1 beat
  Eighth // 0.5 beat
  Sixteenth // 0.25 beat
} derive(Eq, Debug)

///|
/// A single scored note event with pitch, octave, duration, and velocity volume.
pub struct ScoreItem {
  note : Note
  octave : Int
  duration : Duration
  volume : Double
} derive(Eq, Debug)

///|
/// Creates a new ScoreItem.
pub fn ScoreItem::new(
  note : Note,
  octave : Int,
  duration : Duration,
  volume : Double
) -> ScoreItem {
  let v = if volume < 0.0 { 0.0 } else if volume > 1.0 { 1.0 } else { volume }
  { note, octave, duration, volume: v }
}

///|
/// Calculates exact fundamental frequency in Hertz based on A4 = 440 Hz standard.
pub fn note_to_frequency(note : Note, octave : Int) -> Double {
  match note {
    Rest => 0.0
    _ => {
      let semitone_offset = match note {
        C => 0
        Cs => 1
        D => 2
        Ds => 3
        E => 4
        F => 5
        Fs => 6
        G => 7
        Gs => 8
        A => 9
        As => 10
        B => 11
        Rest => 0
      }
      // MIDI note number: C0 is 12, A4 is 69
      let midi_note = (octave + 1) * 12 + semitone_offset
      let exponent = (midi_note - 69).to_double() / 12.0
      440.0 * @math.pow(2.0, exponent)
    }
  }
}

///|
/// Converts Duration enum to duration in seconds based on Tempo BPM.
pub fn duration_to_seconds(duration : Duration, bpm : Int) -> Double {
  let tempo = if bpm <= 20 { 120.0 } else { bpm.to_double() }
  let beat_sec = 60.0 / tempo // Length of 1 quarter note in seconds
  match duration {
    Whole => beat_sec * 4.0
    Half => beat_sec * 2.0
    Quarter => beat_sec * 1.0
    Eighth => beat_sec * 0.5
    Sixteenth => beat_sec * 0.25
  }
}

///|
/// A musical sequence of notes played sequentially.
pub struct Score {
  items : Array[ScoreItem]
} derive(Eq, Debug)

///|
/// Creates an empty musical score.
pub fn Score::new() -> Score {
  { items: [] }
}

///|
/// Appends a note to the musical score.
pub fn Score::add(
  self : Score,
  note : Note,
  octave : Int,
  duration : Duration,
  volume : Double
) -> Unit {
  self.items.push(ScoreItem::new(note, octave, duration, volume))
}

///|
/// Creates a classic retro C Major ascending/descending arpeggio.
pub fn Score::arpeggio_c_major() -> Score {
  let s = Score::new()
  s.add(C, 4, Eighth, 0.8)
  s.add(E, 4, Eighth, 0.8)
  s.add(G, 4, Eighth, 0.8)
  s.add(C, 5, Quarter, 0.9)
  s.add(G, 4, Eighth, 0.8)
  s.add(E, 4, Eighth, 0.8)
  s.add(C, 4, Half, 0.85)
  s
}

///|
/// Creates a triumphant retro game victory fanfare jingle.
pub fn Score::victory_fanfare() -> Score {
  let s = Score::new()
  s.add(C, 4, Sixteenth, 0.8)
  s.add(C, 4, Sixteenth, 0.8)
  s.add(C, 4, Sixteenth, 0.8)
  s.add(C, 4, Eighth, 0.8)
  s.add(Gs, 3, Eighth, 0.8)
  s.add(As, 3, Eighth, 0.8)
  s.add(C, 4, Quarter, 0.9)
  s.add(Rest, 4, Sixteenth, 0.0)
  s.add(As, 3, Sixteenth, 0.8)
  s.add(C, 4, Half, 0.95)
  s
}

///|
/// Renders an entire Score into an AudioBuffer using the specified waveform and ADSR articulation.
pub fn render_score(
  score : Score,
  bpm : Int,
  waveform : Waveform,
  adsr : ADSR,
  sample_rate : Int
) -> AudioBuffer {
  let sr = if sample_rate <= 0 { 44100 } else { sample_rate }
  let master = AudioBuffer::new(sr, 0)

  for i = 0; i < score.items.length(); i = i + 1 {
    let item = score.items[i]
    let dur = duration_to_seconds(item.duration, bpm)
    let freq = note_to_frequency(item.note, item.octave)

    if item.note == Rest || freq <= 0.0 {
      let silent_count = (dur * sr.to_double()).to_int()
      let silence = AudioBuffer::with_silence(sr, silent_count)
      master.mix(silence, master.length(), 0.0)
    } else {
      let tone = render_tone(waveform, freq, dur, sr, item.volume)
      tone.apply_adsr(adsr, Exponential)
      master.mix(tone, master.length(), 1.0)
    }
  }

  master
}
