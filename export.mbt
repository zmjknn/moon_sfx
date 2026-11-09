///|
/// Quick one-liner helper to generate a Laser sound effect WAV byte array.
pub fn play_laser_wav(seed : UInt) -> Bytes {
  let params = SfxParams::laser(seed)
  let buffer = params.synthesize(44100)
  encode_wav_16bit(buffer)
}

///|
/// Quick one-liner helper to generate a Jump sound effect WAV byte array.
pub fn play_jump_wav(seed : UInt) -> Bytes {
  let params = SfxParams::jump(seed)
  let buffer = params.synthesize(44100)
  encode_wav_16bit(buffer)
}

///|
/// Quick one-liner helper to generate a Coin pickup sound effect WAV byte array.
pub fn play_coin_wav(seed : UInt) -> Bytes {
  let params = SfxParams::coin(seed)
  let buffer = params.synthesize(44100)
  encode_wav_16bit(buffer)
}

///|
/// Quick one-liner helper to generate an Explosion sound effect WAV byte array.
pub fn play_explosion_wav(seed : UInt) -> Bytes {
  let params = SfxParams::explosion(seed)
  let buffer = params.synthesize(44100)
  encode_wav_16bit(buffer)
}

///|
/// Quick one-liner helper to generate a Hit / Hurt sound effect WAV byte array.
pub fn play_hit_wav(seed : UInt) -> Bytes {
  let params = SfxParams::hit(seed)
  let buffer = params.synthesize(44100)
  encode_wav_16bit(buffer)
}

///|
/// Quick one-liner helper to generate a Powerup sound effect WAV byte array.
pub fn play_powerup_wav(seed : UInt) -> Bytes {
  let params = SfxParams::powerup(seed)
  let buffer = params.synthesize(44100)
  encode_wav_16bit(buffer)
}

///|
/// Quick one-liner helper to generate a Blip click sound effect WAV byte array.
pub fn play_blip_wav(seed : UInt) -> Bytes {
  let params = SfxParams::blip(seed)
  let buffer = params.synthesize(44100)
  encode_wav_16bit(buffer)
}

///|
/// Quick one-liner helper to generate a Periodic Repeating Burst sound effect WAV byte array.
pub fn play_burst_wav(seed : UInt) -> Bytes {
  let params = SfxParams::burst(seed)
  let buffer = params.synthesize(44100)
  encode_wav_16bit(buffer)
}

///|
/// Generates a complete, self-contained interactive HTML5 audio playground page with embedded base64 sounds.
pub fn generate_html_playground() -> String {
  let laser_uri = SfxParams::laser(1U).synthesize(44100).to_data_uri()
  let jump_uri = SfxParams::jump(2U).synthesize(44100).to_data_uri()
  let coin_uri = SfxParams::coin(3U).synthesize(44100).to_data_uri()
  let explosion_uri = SfxParams::explosion(4U).synthesize(44100).to_data_uri()
  let hit_uri = SfxParams::hit(5U).synthesize(44100).to_data_uri()
  let powerup_uri = SfxParams::powerup(6U).synthesize(44100).to_data_uri()
  let blip_uri = SfxParams::blip(7U).synthesize(44100).to_data_uri()
  let burst_uri = SfxParams::burst(8U).synthesize(44100).to_data_uri()

  let fanfare_score = Score::victory_fanfare()
  let fanfare_buffer = render_score(
    fanfare_score,
    140,
    Square(0.5),
    ADSR::organ(),
    44100,
  )
  let fanfare_uri = fanfare_buffer.to_data_uri()

  // New features: FM presets
  let fm_piano_uri = fm_electric_piano(440.0, 1.2, 44100).to_data_uri()
  let fm_bell_uri = fm_bell(880.0, 1.5, 44100).to_data_uri()
  let fm_bass_uri = fm_slap_bass(110.0, 0.8, 44100).to_data_uri()

  // New features: MML melody
  let mml_uri = render_mml("T140 O4 C8 E8 G8 > C8 < B8 G8 C2", Square(0.5), ADSR::organ(), 44100).to_data_uri()

  // New features: Stereo Panning Demo (Laser panned Left, Coin panned Right)
  let mixer_demo = Mixer::new(44100)
  mixer_demo.add_track(SfxParams::laser(1U).synthesize(44100), 0.0, 0.85, -0.9)
  mixer_demo.add_track(SfxParams::coin(3U).synthesize(44100), 0.25, 0.85, 0.9)
  let stereo_demo_uri = mixer_demo.render_stereo().to_data_uri()

  let sb = StringBuilder()
  sb.write_string("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n")
  sb.write_string("  <meta charset=\"UTF-8\">\n")
  sb.write_string("  <title>moon_sfx - Procedural Retro Audio Playground</title>\n")
  sb.write_string("  <style>\n")
  sb.write_string("    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, monospace; background: #0f172a; color: #f8fafc; margin: 0; padding: 2rem; }\n")
  sb.write_string("    .container { max-width: 900px; margin: 0 auto; }\n")
  sb.write_string("    h1 { color: #38bdf8; font-size: 2.2rem; margin-bottom: 0.5rem; text-shadow: 0 0 10px rgba(56,189,248,0.3); }\n")
  sb.write_string("    p.subtitle { color: #94a3b8; font-size: 1.1rem; margin-bottom: 2rem; }\n")
  sb.write_string("    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 1.2rem; }\n")
  sb.write_string("    .card { background: #1e293b; border: 1px solid #334155; border-radius: 12px; padding: 1.25rem; transition: transform 0.2s, border-color 0.2s; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); }\n")
  sb.write_string("    .card:hover { transform: translateY(-3px); border-color: #38bdf8; }\n")
  sb.write_string("    .btn { width: 100%; background: #0284c7; color: white; border: none; padding: 0.8rem; border-radius: 8px; font-size: 1rem; font-weight: bold; cursor: pointer; transition: background 0.15s; }\n")
  sb.write_string("    .btn:hover { background: #0369a1; }\n")
  sb.write_string("    .tag { display: inline-block; background: #334155; color: #38bdf8; font-size: 0.75rem; padding: 0.2rem 0.5rem; border-radius: 4px; margin-bottom: 0.75rem; }\n")
  sb.write_string("    audio { width: 100%; margin-top: 0.75rem; filter: invert(0.9) hue-rotate(180deg); }\n")
  sb.write_string("  </style>\n</head>\n<body>\n<div class=\"container\">\n")
  sb.write_string("  <h1>🎮 moon_sfx Audio Playground</h1>\n")
  sb.write_string("  <p class=\"subtitle\">Pure MoonBit Procedural 8-bit Retro Game Sound FX & Chiptune Synthesizer</p>\n")
  sb.write_string("  <div class=\"grid\">\n")

  let add_card = fn(name : String, tag : String, desc : String, uri : String) -> Unit {
    sb.write_string("    <div class=\"card\">\n")
    sb.write_string("      <span class=\"tag\">" + tag + "</span>\n")
    sb.write_string("      <h3 style=\"margin: 0 0 0.5rem 0;\">" + name + "</h3>\n")
    sb.write_string("      <p style=\"font-size: 0.85rem; color: #94a3b8; margin: 0 0 1rem 0;\">" + desc + "</p>\n")
    sb.write_string("      <button class=\"btn\" onclick=\"new Audio('" + uri + "').play()\">▶ Play Sound</button>\n")
    sb.write_string("      <audio controls src=\"" + uri + "\"></audio>\n")
    sb.write_string("    </div>\n")
  }

  add_card("Laser Shoot", "SFXR PRESET", "High-frequency downward frequency sweep with square/sawtooth timbre.", laser_uri)
  add_card("Jump", "SFXR PRESET", "Ascending frequency jump with snappy square wave decay.", jump_uri)
  add_card("Coin / Pickup", "SFXR PRESET", "Two-tone arpeggio frequency step simulating retro coin collecting.", coin_uri)
  add_card("Explosion", "SFXR PRESET", "Low-pass filtered white noise with punch sustain and heavy decay.", explosion_uri)
  add_card("Hit / Hurt", "SFXR PRESET", "Crunchy noise burst with rapid downward frequency plunge.", hit_uri)
  add_card("Powerup", "SFXR PRESET", "Triumphant ascending saw slide accompanied by vibrato modulation.", powerup_uri)
  add_card("UI Blip", "SFXR PRESET", "Ultra-short high pitch click designed for menu navigation.", blip_uri)
  add_card("Repeating Burst", "REPEAT & PHASER", "Rapid cycle-repeating burst demonstrating periodic repeat speed and phaser sweep.", burst_uri)
  add_card("Victory Fanfare", "SEQUENCER MELODY", "Multi-note 8-bit victory melody rendered via the built-in MML sequencer.", fanfare_uri)
  add_card("FM Electric Piano", "FM SYNTHESIS", "Yamaha DX7 style 1:1 harmonic ratio FM electric piano with percussive metallic chime.", fm_piano_uri)
  add_card("FM Crystal Bell", "FM SYNTHESIS", "Inharmonic metallic church bell with resonant physical frequency modulation.", fm_bell_uri)
  add_card("FM Slap Bass", "FM SYNTHESIS", "Sega Genesis 16-bit YM2612 style funk slap bass with sharp 2nd harmonic transient.", fm_bass_uri)
  add_card("MML Retro Melody", "MML COMPILER", "Rendered directly from string 'T140 O4 C8 E8 G8 > C8 < B8 G8 C2'.", mml_uri)
  add_card("Stereo Spatial Mixer", "STEREO PANNING", "Left-to-right constant-power spatial separation: Laser on Left (-0.9), Coin on Right (+0.9).", stereo_demo_uri)

  sb.write_string("  </div>\n")
  sb.write_string("</div>\n</body>\n</html>\n")
  sb.to_string()
}
