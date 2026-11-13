///|
/// Represents the fundamental wave shapes used for sound synthesis.
#derive(Eq, Debug)
pub(all) enum Waveform {
  Sine
  Square(Double) // Duty cycle, typically 0.5 (50%)
  Sawtooth
  Triangle
  Noise
}

///|
/// A mono linear floating-point audio buffer holding raw PCM samples normalized between -1.0 and 1.0.
#derive(Eq)
pub struct AudioBuffer {
  sample_rate : Int32
  samples : Array[Double]
}

///|
/// Creates a new empty AudioBuffer with specified sample rate and reserved capacity.
pub fn AudioBuffer::new(sample_rate : Int32, _capacity : Int32) -> AudioBuffer {
  { sample_rate, samples: Array::make(0, 0.0), }
}

///|
/// Creates an AudioBuffer prefilled with silent samples (0.0).
pub fn AudioBuffer::with_silence(
  sample_rate : Int32,
  count : Int32,
) -> AudioBuffer {
  let cnt = if count < 0 { 0 } else { count }
  { sample_rate, samples: Array::make(cnt, 0.0), }
}

///|
/// Returns the sample rate of the audio buffer in Hz.
pub fn AudioBuffer::sample_rate(self : AudioBuffer) -> Int32 {
  self.sample_rate
}

///|
/// Returns the raw samples array.
pub fn AudioBuffer::samples(self : AudioBuffer) -> Array[Double] {
  self.samples
}

///|
/// Returns the number of samples in the buffer.
pub fn AudioBuffer::length(self : AudioBuffer) -> Int32 {
  self.samples.length()
}

///|
/// Returns total duration of the buffer in seconds.
pub fn AudioBuffer::duration(self : AudioBuffer) -> Double {
  if self.sample_rate <= 0 {
    0.0
  } else {
    self.samples.length().to_double() / self.sample_rate.to_double()
  }
}

///|
/// Gets sample at index with bounds checking, returning 0.0 if out of bounds.
pub fn AudioBuffer::get(self : AudioBuffer, index : Int32) -> Double {
  if index >= 0 && index < self.samples.length() {
    self.samples[index]
  } else {
    0.0
  }
}

///|
/// Sets sample at index if within bounds.
pub fn AudioBuffer::set(
  self : AudioBuffer,
  index : Int32,
  value : Double,
) -> Unit {
  if index >= 0 && index < self.samples.length() {
    self.samples[index] = value
  }
}

///|
/// Appends a sample to the end of the buffer.
pub fn AudioBuffer::push(self : AudioBuffer, sample : Double) -> Unit {
  self.samples.push(sample)
}

///|
/// Hard clamps all samples to the range [min, max].
pub fn AudioBuffer::clamp(
  self : AudioBuffer,
  min : Double,
  max : Double,
) -> Unit {
  for i = 0; i < self.samples.length(); i = i + 1 {
    let s = self.samples[i]
    if s < min {
      self.samples[i] = min
    } else if s > max {
      self.samples[i] = max
    }
  }
}

///|
/// Normalizes peak amplitude to `target_peak` (usually 0.95 or 1.0) to prevent clipping.
pub fn AudioBuffer::normalize(self : AudioBuffer, target_peak : Double) -> Unit {
  let mut max_abs = 0.0
  for i = 0; i < self.samples.length(); i = i + 1 {
    let a = self.samples[i].abs()
    if a > max_abs {
      max_abs = a
    }
  }
  if max_abs > 0.000001 {
    let scale = target_peak / max_abs
    for i = 0; i < self.samples.length(); i = i + 1 {
      self.samples[i] = self.samples[i] * scale
    }
  }
}

///|
/// Multiplies all samples by a gain factor.
pub fn AudioBuffer::amplify(self : AudioBuffer, gain : Double) -> Unit {
  for i = 0; i < self.samples.length(); i = i + 1 {
    self.samples[i] = self.samples[i] * gain
  }
}

///|
/// Smoothly soft-limits samples exceeding `threshold` using an algebraic saturation curve.
/// Prevents harsh digital clipping when multiple sounds or loud gains are summed together.
pub fn AudioBuffer::soft_limit(self : AudioBuffer, threshold : Double) -> Unit {
  let th = if threshold <= 0.1 {
    0.1
  } else if threshold > 0.95 {
    0.95
  } else {
    threshold
  }
  let headroom = 1.0 - th
  for i = 0; i < self.samples.length(); i = i + 1 {
    let s = self.samples[i]
    if s > th {
      let diff = s - th
      self.samples[i] = th + headroom * (diff / (1.0 + diff))
    } else if s < -th {
      let diff = -s - th
      self.samples[i] = -(th + headroom * (diff / (1.0 + diff)))
    }
  }
}

///|
/// A stereo audio buffer containing separate left and right PCM audio channels.
#derive(Eq)
pub struct StereoBuffer {
  sample_rate : Int32
  left : AudioBuffer
  right : AudioBuffer
}

///|
/// Creates a new StereoBuffer with specified sample rate and capacity.
pub fn StereoBuffer::new(sample_rate : Int32, capacity : Int32) -> StereoBuffer {
  {
    sample_rate,
    left: AudioBuffer::new(sample_rate, capacity),
    right: AudioBuffer::new(sample_rate, capacity),
  }
}

///|
/// Creates a StereoBuffer from two individual mono channels.
pub fn StereoBuffer::from_channels(
  left : AudioBuffer,
  right : AudioBuffer,
) -> StereoBuffer {
  let sr = left.sample_rate
  { sample_rate: sr, left, right, }
}

///|
/// Converts a mono AudioBuffer into a StereoBuffer using the Constant-Power Panning Law.
/// `pan` parameter: -1.0 = 100% Left, 0.0 = Center (balanced), 1.0 = 100% Right.
pub fn AudioBuffer::to_stereo(self : AudioBuffer, pan : Double) -> StereoBuffer {
  let p = if pan < -1.0 { -1.0 } else if pan > 1.0 { 1.0 } else { pan }
  let (gain_left, gain_right) = if p <= -0.9999 {
    (1.0, 0.0)
  } else if p >= 0.9999 {
    (0.0, 1.0)
  } else {
    // Constant-power panning angle: [-1.0, 1.0] -> [0, pi/2]
    let pi_fourth = 3.141592653589793 / 4.0
    let angle = (p + 1.0) * pi_fourth
    (@math.cos(angle), @math.sin(angle))
  }

  let left_samples = Array::make(self.samples.length(), 0.0)
  let right_samples = Array::make(self.samples.length(), 0.0)
  for i = 0; i < self.samples.length(); i = i + 1 {
    let s = self.samples[i]
    left_samples[i] = s * gain_left
    right_samples[i] = s * gain_right
  }

  {
    sample_rate: self.sample_rate,
    left: { sample_rate: self.sample_rate, samples: left_samples, },
    right: { sample_rate: self.sample_rate, samples: right_samples, },
  }
}

///|
/// Convenience helper to create a StereoBuffer from a mono buffer and pan value.
pub fn StereoBuffer::from_mono(
  mono : AudioBuffer,
  pan : Double,
) -> StereoBuffer {
  mono.to_stereo(pan)
}

///|
/// Returns the sample rate of the stereo buffer.
pub fn StereoBuffer::sample_rate(self : StereoBuffer) -> Int32 {
  self.sample_rate
}

///|
/// Returns the left channel AudioBuffer.
pub fn StereoBuffer::left(self : StereoBuffer) -> AudioBuffer {
  self.left
}

///|
/// Returns the right channel AudioBuffer.
pub fn StereoBuffer::right(self : StereoBuffer) -> AudioBuffer {
  self.right
}

///|
/// Returns the number of sample frames in the stereo buffer.
pub fn StereoBuffer::length(self : StereoBuffer) -> Int32 {
  let len_l = self.left.length()
  let len_r = self.right.length()
  if len_l > len_r {
    len_l
  } else {
    len_r
  }
}

///|
/// Returns the duration of the stereo buffer in seconds.
pub fn StereoBuffer::duration(self : StereoBuffer) -> Double {
  self.left.duration()
}

///|
/// Normalizes both channels of the stereo buffer relative to the highest peak.
pub fn StereoBuffer::normalize(
  self : StereoBuffer,
  target_peak : Double,
) -> Unit {
  let mut max_abs = 0.0
  for i = 0; i < self.left.samples.length(); i = i + 1 {
    let a = self.left.samples[i].abs()
    if a > max_abs {
      max_abs = a
    }
  }
  for i = 0; i < self.right.samples.length(); i = i + 1 {
    let a = self.right.samples[i].abs()
    if a > max_abs {
      max_abs = a
    }
  }
  if max_abs > 0.000001 {
    let scale = target_peak / max_abs
    self.left.amplify(scale)
    self.right.amplify(scale)
  }
}

///|
/// Amplifies both channels by a gain multiplier.
pub fn StereoBuffer::amplify(self : StereoBuffer, gain : Double) -> Unit {
  self.left.amplify(gain)
  self.right.amplify(gain)
}

///|
/// Deep copies a StereoBuffer.
pub fn StereoBuffer::clone(self : StereoBuffer) -> StereoBuffer {
  {
    sample_rate: self.sample_rate,
    left: self.left.clone(),
    right: self.right.clone(),
  }
}

///|
/// Mixes another audio buffer into this buffer starting at `offset_samples` with volume scaling.
pub fn AudioBuffer::mix(
  self : AudioBuffer,
  other : AudioBuffer,
  offset_samples : Int32,
  volume : Double,
) -> Unit {
  let offset = if offset_samples < 0 { 0 } else { offset_samples }
  let needed_len = offset + other.samples.length()
  while self.samples.length() < needed_len {
    self.samples.push(0.0)
  }
  for i = 0; i < other.samples.length(); i = i + 1 {
    let target_idx = offset + i
    self.samples[target_idx] = self.samples[target_idx] +
      other.samples[i] * volume
  }
}

///|
/// Creates a deep copy of this AudioBuffer.
pub fn AudioBuffer::clone(self : AudioBuffer) -> AudioBuffer {
  let copied = Array::make(self.samples.length(), 0.0)
  for i = 0; i < self.samples.length(); i = i + 1 {
    copied[i] = self.samples[i]
  }
  { sample_rate: self.sample_rate, samples: copied, }
}

///|
/// Converts float samples in [-1.0, 1.0] to signed 16-bit integers [-32768, 32767].
pub fn AudioBuffer::to_16bit_pcm(self : AudioBuffer) -> Array[Int32] {
  let result = Array::make(self.samples.length(), 0)
  for i = 0; i < self.samples.length(); i = i + 1 {
    let mut s = self.samples[i]
    if s > 1.0 {
      s = 1.0
    } else if s < -1.0 {
      s = -1.0
    }
    let pcm = (s * 32767.0).to_int()
    result[i] = pcm
  }
  result
}

///|
/// Converts float samples in [-1.0, 1.0] to unsigned 8-bit bytes [0, 255] with center at 128.
pub fn AudioBuffer::to_8bit_pcm(self : AudioBuffer) -> Array[Byte] {
  let result = Array::make(self.samples.length(), b'\x00')
  for i = 0; i < self.samples.length(); i = i + 1 {
    let mut s = self.samples[i]
    if s > 1.0 {
      s = 1.0
    } else if s < -1.0 {
      s = -1.0
    }
    let pcm = ((s + 1.0) * 127.5).to_int()
    let clamped = if pcm < 0 { 0 } else if pcm > 255 { 255 } else { pcm }
    result[i] = clamped.to_byte()
  }
  result
}
