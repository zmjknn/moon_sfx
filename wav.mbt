///|
/// Writes a 16-bit unsigned integer into FixedArray[Byte] in Little-Endian order.
fn write_u16_le(b : FixedArray[Byte], offset : Int, val : Int) -> Unit {
  b[offset] = (val & 0xff).to_byte()
  b[offset + 1] = ((val >> 8) & 0xff).to_byte()
}

///|
/// Writes a 32-bit integer into FixedArray[Byte] in Little-Endian order.
fn write_u32_le(b : FixedArray[Byte], offset : Int, val : Int) -> Unit {
  b[offset] = (val & 0xff).to_byte()
  b[offset + 1] = ((val >> 8) & 0xff).to_byte()
  b[offset + 2] = ((val >> 16) & 0xff).to_byte()
  b[offset + 3] = ((val >> 24) & 0xff).to_byte()
}

///|
/// Encodes an AudioBuffer into standard 16-bit signed PCM Microsoft RIFF WAVE binary bytes.
pub fn encode_wav_16bit(buffer : AudioBuffer) -> Bytes {
  let num_samples = buffer.length()
  let sample_rate = buffer.sample_rate
  let num_channels = 1
  let bits_per_sample = 16
  let byte_rate = sample_rate * num_channels * bits_per_sample / 8
  let block_align = num_channels * bits_per_sample / 8
  let data_size = num_samples * block_align
  let chunk_size = 36 + data_size
  let total_size = 44 + data_size

  let b = FixedArray::make(total_size, b'\x00')

  // 00..03: "RIFF"
  b[0] = b'R'
  b[1] = b'I'
  b[2] = b'F'
  b[3] = b'F'

  // 04..07: ChunkSize
  write_u32_le(b, 4, chunk_size)

  // 08..11: "WAVE"
  b[8] = b'W'
  b[9] = b'A'
  b[10] = b'V'
  b[11] = b'E'

  // 12..15: "fmt "
  b[12] = b'f'
  b[13] = b'm'
  b[14] = b't'
  b[15] = b' '

  // 16..19: Subchunk1Size (16 for PCM)
  write_u32_le(b, 16, 16)

  // 20..21: AudioFormat (1 = PCM linear)
  write_u16_le(b, 20, 1)

  // 22..23: NumChannels
  write_u16_le(b, 22, num_channels)

  // 24..27: SampleRate
  write_u32_le(b, 24, sample_rate)

  // 28..31: ByteRate
  write_u32_le(b, 28, byte_rate)

  // 32..33: BlockAlign
  write_u16_le(b, 32, block_align)

  // 34..35: BitsPerSample
  write_u16_le(b, 34, bits_per_sample)

  // 36..39: "data"
  b[36] = b'd'
  b[37] = b'a'
  b[38] = b't'
  b[39] = b'a'

  // 40..43: Subchunk2Size
  write_u32_le(b, 40, data_size)

  // 44..end: PCM samples
  let samples = buffer.samples
  for i = 0; i < num_samples; i = i + 1 {
    let mut s = samples[i]
    if s > 1.0 {
      s = 1.0
    } else if s < -1.0 {
      s = -1.0
    }
    let pcm = (s * 32767.0).to_int()
    write_u16_le(b, 44 + i * 2, pcm)
  }

  let list = []
  for byte in b {
    list.push(byte)
  }
  Bytes::from_array(list)
}

///|
/// Encodes an AudioBuffer into standard 8-bit unsigned PCM Microsoft RIFF WAVE binary bytes.
pub fn encode_wav_8bit(buffer : AudioBuffer) -> Bytes {
  let num_samples = buffer.length()
  let sample_rate = buffer.sample_rate
  let num_channels = 1
  let bits_per_sample = 8
  let byte_rate = sample_rate * num_channels * bits_per_sample / 8
  let block_align = num_channels * bits_per_sample / 8
  let data_size = num_samples * block_align
  let chunk_size = 36 + data_size
  let total_size = 44 + data_size

  let b = FixedArray::make(total_size, b'\x00')

  // RIFF header
  b[0] = b'R'
  b[1] = b'I'
  b[2] = b'F'
  b[3] = b'F'
  write_u32_le(b, 4, chunk_size)
  b[8] = b'W'
  b[9] = b'A'
  b[10] = b'V'
  b[11] = b'E'

  // fmt chunk
  b[12] = b'f'
  b[13] = b'm'
  b[14] = b't'
  b[15] = b' '
  write_u32_le(b, 16, 16)
  write_u16_le(b, 20, 1)
  write_u16_le(b, 22, num_channels)
  write_u32_le(b, 24, sample_rate)
  write_u32_le(b, 28, byte_rate)
  write_u16_le(b, 32, block_align)
  write_u16_le(b, 34, bits_per_sample)

  // data chunk
  b[36] = b'd'
  b[37] = b'a'
  b[38] = b't'
  b[39] = b'a'
  write_u32_le(b, 40, data_size)

  // 8-bit unsigned PCM samples [0, 255]
  let samples = buffer.samples
  for i = 0; i < num_samples; i = i + 1 {
    let mut s = samples[i]
    if s > 1.0 {
      s = 1.0
    } else if s < -1.0 {
      s = -1.0
    }
    let pcm = ((s + 1.0) * 127.5).to_int()
    let clamped = if pcm < 0 { 0 } else if pcm > 255 { 255 } else { pcm }
    b[44 + i] = clamped.to_byte()
  }

  let list = []
  for byte in b {
    list.push(byte)
  }
  Bytes::from_array(list)
}

///|
let base64_table : FixedArray[Char] = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
  'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
  'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
  't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
  '8', '9', '+', '/',
]

///|
/// Encodes raw binary bytes into a standard RFC 4648 Base64 string.
pub fn to_base64(bytes : Bytes) -> String {
  let len = bytes.length()
  if len == 0 {
    return ""
  }
  let sb = StringBuilder()
  let mut i = 0
  while i < len {
    let b0 = bytes[i].to_int()
    let b1 = if i + 1 < len { bytes[i + 1].to_int() } else { 0 }
    let b2 = if i + 2 < len { bytes[i + 2].to_int() } else { 0 }

    let triplet = (b0 << 16) | (b1 << 8) | b2

    let c0 = (triplet >> 18) & 0x3f
    let c1 = (triplet >> 12) & 0x3f
    let c2 = (triplet >> 6) & 0x3f
    let c3 = triplet & 0x3f

    sb.write_char(base64_table[c0])
    sb.write_char(base64_table[c1])

    if i + 1 < len {
      sb.write_char(base64_table[c2])
    } else {
      sb.write_char('=')
    }

    if i + 2 < len {
      sb.write_char(base64_table[c3])
    } else {
      sb.write_char('=')
    }

    i = i + 3
  }
  sb.to_string()
}

///|
/// Encodes an AudioBuffer as a self-contained Base64 Data URI string ("data:audio/wav;base64,...").
pub fn AudioBuffer::to_data_uri(self : AudioBuffer) -> String {
  let wav_bytes = encode_wav_16bit(self)
  "data:audio/wav;base64," + to_base64(wav_bytes)
}

///|
/// Encodes a StereoBuffer into standard 2-channel 16-bit signed PCM Microsoft RIFF WAVE binary bytes.
pub fn encode_wav_stereo_16bit(stereo : StereoBuffer) -> Bytes {
  let num_samples = stereo.length()
  let sample_rate = stereo.sample_rate
  let num_channels = 2
  let bits_per_sample = 16
  let block_align = num_channels * bits_per_sample / 8 // 4 bytes per frame
  let byte_rate = sample_rate * block_align
  let data_size = num_samples * block_align
  let chunk_size = 36 + data_size
  let total_size = 44 + data_size

  let b = FixedArray::make(total_size, b'\x00')

  // 00..03: "RIFF"
  b[0] = b'R'
  b[1] = b'I'
  b[2] = b'F'
  b[3] = b'F'

  // 04..07: ChunkSize
  write_u32_le(b, 4, chunk_size)

  // 08..11: "WAVE"
  b[8] = b'W'
  b[9] = b'A'
  b[10] = b'V'
  b[11] = b'E'

  // 12..15: "fmt "
  b[12] = b'f'
  b[13] = b'm'
  b[14] = b't'
  b[15] = b' '

  // 16..19: Subchunk1Size (16 for PCM)
  write_u32_le(b, 16, 16)

  // 20..21: AudioFormat (1 = PCM linear)
  write_u16_le(b, 20, 1)

  // 22..23: NumChannels (2)
  write_u16_le(b, 22, num_channels)

  // 24..27: SampleRate
  write_u32_le(b, 24, sample_rate)

  // 28..31: ByteRate
  write_u32_le(b, 28, byte_rate)

  // 32..33: BlockAlign (4)
  write_u16_le(b, 32, block_align)

  // 34..35: BitsPerSample (16)
  write_u16_le(b, 34, bits_per_sample)

  // 36..39: "data"
  b[36] = b'd'
  b[37] = b'a'
  b[38] = b't'
  b[39] = b'a'

  // 40..43: Subchunk2Size
  write_u32_le(b, 40, data_size)

  // 44..end: Interleaved PCM samples (L0, R0, L1, R1, ...)
  let left_samples = stereo.left.samples
  let right_samples = stereo.right.samples
  for i = 0; i < num_samples; i = i + 1 {
    let mut sl = if i < left_samples.length() { left_samples[i] } else { 0.0 }
    if sl > 1.0 { sl = 1.0 } else if sl < -1.0 { sl = -1.0 }
    let pcml = (sl * 32767.0).to_int()
    write_u16_le(b, 44 + i * 4, pcml)

    let mut sr = if i < right_samples.length() { right_samples[i] } else { 0.0 }
    if sr > 1.0 { sr = 1.0 } else if sr < -1.0 { sr = -1.0 }
    let pcmr = (sr * 32767.0).to_int()
    write_u16_le(b, 44 + i * 4 + 2, pcmr)
  }

  let list = []
  for byte in b {
    list.push(byte)
  }
  Bytes::from_array(list)
}

///|
/// Encodes a StereoBuffer as a self-contained Base64 Data URI string.
pub fn StereoBuffer::to_data_uri(self : StereoBuffer) -> String {
  let wav_bytes = encode_wav_stereo_16bit(self)
  "data:audio/wav;base64," + to_base64(wav_bytes)
}

///|
/// Metadata information parsed from a standard RIFF WAVE file header.
pub struct WavInfo {
  sample_rate : Int
  num_channels : Int
  bits_per_sample : Int
  num_samples : Int
  duration : Double
} derive(Eq, Debug)

///|
/// Reads a 16-bit unsigned integer from Bytes in Little-Endian order.
fn read_u16_le(bytes : Bytes, offset : Int) -> Int {
  let b0 = bytes[offset].to_int() & 0xff
  let b1 = bytes[offset + 1].to_int() & 0xff
  b0 | (b1 << 8)
}

///|
/// Reads a 32-bit unsigned integer from Bytes in Little-Endian order.
fn read_u32_le(bytes : Bytes, offset : Int) -> Int {
  let b0 = bytes[offset].to_int() & 0xff
  let b1 = bytes[offset + 1].to_int() & 0xff
  let b2 = bytes[offset + 2].to_int() & 0xff
  let b3 = bytes[offset + 3].to_int() & 0xff
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

///|
/// Inspects metadata from a RIFF WAVE byte stream without fully decoding all audio samples.
pub fn inspect_wav(bytes : Bytes) -> Result[WavInfo, String] {
  if bytes.length() < 44 {
    return Err("Invalid WAV file: size is less than 44-byte standard header")
  }
  // Check "RIFF"
  if bytes[0] != b'R' || bytes[1] != b'I' || bytes[2] != b'F' || bytes[3] != b'F' {
    return Err("Invalid WAV file: missing 'RIFF' magic signature")
  }
  // Check "WAVE"
  if bytes[8] != b'W' || bytes[9] != b'A' || bytes[10] != b'V' || bytes[11] != b'E' {
    return Err("Invalid WAV file: missing 'WAVE' format signature")
  }
  // Search for fmt and data chunks
  let mut offset = 12
  let mut fmt_found = false
  let mut data_found = false
  let mut num_channels = 1
  let mut sample_rate = 44100
  let mut bits_per_sample = 16
  let mut data_size = 0

  while offset + 8 <= bytes.length() {
    let c0 = bytes[offset]
    let c1 = bytes[offset + 1]
    let c2 = bytes[offset + 2]
    let c3 = bytes[offset + 3]
    let chunk_len = read_u32_le(bytes, offset + 4)

    if c0 == b'f' && c1 == b'm' && c2 == b't' && c3 == b' ' {
      fmt_found = true
      let audio_format = read_u16_le(bytes, offset + 8)
      if audio_format != 1 {
        return Err("Unsupported WAV compression format: only uncompressed PCM (format=1) is supported")
      }
      num_channels = read_u16_le(bytes, offset + 10)
      sample_rate = read_u32_le(bytes, offset + 12)
      bits_per_sample = read_u16_le(bytes, offset + 22)
    } else if c0 == b'd' && c1 == b'a' && c2 == b't' && c3 == b'a' {
      data_found = true
      data_size = chunk_len
      break
    }

    offset = offset + 8 + chunk_len
  }

  if !fmt_found {
    return Err("Corrupted WAV file: 'fmt ' subchunk not found")
  }
  if !data_found {
    return Err("Corrupted WAV file: 'data' subchunk not found")
  }

  let bytes_per_sample = bits_per_sample / 8
  let block_align = num_channels * bytes_per_sample
  let num_samples = if block_align > 0 { data_size / block_align } else { 0 }
  let duration = if sample_rate > 0 { num_samples.to_double() / sample_rate.to_double() } else { 0.0 }

  Ok({
    sample_rate,
    num_channels,
    bits_per_sample,
    num_samples,
    duration,
  })
}

///|
/// Decodes a RIFF WAVE byte stream into a mono AudioBuffer.
/// If the file is stereo, both channels are averaged into mono.
pub fn decode_wav(bytes : Bytes) -> Result[AudioBuffer, String] {
  let info = match inspect_wav(bytes) {
    Ok(inf) => inf
    Err(e) => return Err(e)
  }

  if info.bits_per_sample != 16 && info.bits_per_sample != 8 {
    return Err("Unsupported bit depth: only 16-bit signed and 8-bit unsigned PCM are supported")
  }

  // Find data offset
  let mut offset = 12
  let mut data_offset = 44
  while offset + 8 <= bytes.length() {
    if bytes[offset] == b'd' && bytes[offset + 1] == b'a' && bytes[offset + 2] == b't' && bytes[offset + 3] == b'a' {
      data_offset = offset + 8
      break
    }
    let chunk_len = read_u32_le(bytes, offset + 4)
    offset = offset + 8 + chunk_len
  }

  let samples = Array::make(info.num_samples, 0.0)
  let bytes_per_sample = info.bits_per_sample / 8
  let block_align = info.num_channels * bytes_per_sample

  if info.bits_per_sample == 16 {
    for i = 0; i < info.num_samples; i = i + 1 {
      let frame_offset = data_offset + i * block_align
      if frame_offset + block_align > bytes.length() {
        break
      }
      if info.num_channels == 1 {
        let raw = read_u16_le(bytes, frame_offset)
        let signed_val = if raw >= 32768 { raw - 65536 } else { raw }
        samples[i] = signed_val.to_double() / 32768.0
      } else {
        // Average left and right
        let raw_l = read_u16_le(bytes, frame_offset)
        let s_l = if raw_l >= 32768 { raw_l - 65536 } else { raw_l }
        let raw_r = read_u16_le(bytes, frame_offset + 2)
        let s_r = if raw_r >= 32768 { raw_r - 65536 } else { raw_r }
        samples[i] = (s_l.to_double() + s_r.to_double()) / (2.0 * 32768.0)
      }
    }
  } else {
    // 8-bit unsigned PCM
    for i = 0; i < info.num_samples; i = i + 1 {
      let frame_offset = data_offset + i * block_align
      if frame_offset + block_align > bytes.length() {
        break
      }
      if info.num_channels == 1 {
        let b = bytes[frame_offset].to_int() & 0xff
        samples[i] = (b.to_double() - 128.0) / 128.0
      } else {
        let bl = bytes[frame_offset].to_int() & 0xff
        let br = bytes[frame_offset + 1].to_int() & 0xff
        let sl = (bl.to_double() - 128.0) / 128.0
        let sr = (br.to_double() - 128.0) / 128.0
        samples[i] = (sl + sr) * 0.5
      }
    }
  }

  Ok({ sample_rate: info.sample_rate, samples })
}

///|
/// Decodes a 2-channel RIFF WAVE byte stream into a StereoBuffer.
pub fn decode_wav_stereo(bytes : Bytes) -> Result[StereoBuffer, String] {
  let info = match inspect_wav(bytes) {
    Ok(inf) => inf
    Err(e) => return Err(e)
  }

  if info.num_channels != 2 {
    return Err("Expected 2-channel stereo WAV file, but found channel count: " + info.num_channels.to_string())
  }
  if info.bits_per_sample != 16 && info.bits_per_sample != 8 {
    return Err("Unsupported bit depth: only 16-bit and 8-bit are supported")
  }

  let mut offset = 12
  let mut data_offset = 44
  while offset + 8 <= bytes.length() {
    if bytes[offset] == b'd' && bytes[offset + 1] == b'a' && bytes[offset + 2] == b't' && bytes[offset + 3] == b'a' {
      data_offset = offset + 8
      break
    }
    let chunk_len = read_u32_le(bytes, offset + 4)
    offset = offset + 8 + chunk_len
  }

  let left_samples = Array::make(info.num_samples, 0.0)
  let right_samples = Array::make(info.num_samples, 0.0)
  let bytes_per_sample = info.bits_per_sample / 8
  let block_align = info.num_channels * bytes_per_sample

  if info.bits_per_sample == 16 {
    for i = 0; i < info.num_samples; i = i + 1 {
      let frame_offset = data_offset + i * block_align
      if frame_offset + block_align > bytes.length() {
        break
      }
      let raw_l = read_u16_le(bytes, frame_offset)
      let sl = if raw_l >= 32768 { raw_l - 65536 } else { raw_l }
      let raw_r = read_u16_le(bytes, frame_offset + 2)
      let sr = if raw_r >= 32768 { raw_r - 65536 } else { raw_r }
      left_samples[i] = sl.to_double() / 32768.0
      right_samples[i] = sr.to_double() / 32768.0
    }
  } else {
    for i = 0; i < info.num_samples; i = i + 1 {
      let frame_offset = data_offset + i * block_align
      if frame_offset + block_align > bytes.length() {
        break
      }
      let bl = bytes[frame_offset].to_int() & 0xff
      let br = bytes[frame_offset + 1].to_int() & 0xff
      left_samples[i] = (bl.to_double() - 128.0) / 128.0
      right_samples[i] = (br.to_double() - 128.0) / 128.0
    }
  }

  Ok({
    sample_rate: info.sample_rate,
    left: { sample_rate: info.sample_rate, samples: left_samples },
    right: { sample_rate: info.sample_rate, samples: right_samples },
  })
}
