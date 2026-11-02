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
