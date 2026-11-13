///|
/// A single audio track within the multi-track Mixer.
#derive(Eq)
pub struct Track {
  buffer : AudioBuffer
  offset_seconds : Double
  volume : Double
  pan : Double
  mut mute : Bool
}

///|
/// Creates a new Track.
pub fn Track::new(
  buffer : AudioBuffer,
  offset_seconds : Double,
  volume : Double,
  pan : Double,
) -> Track {
  let off = if offset_seconds < 0.0 { 0.0 } else { offset_seconds }
  let vol = if volume < 0.0 { 0.0 } else { volume }
  let p = if pan < -1.0 { -1.0 } else if pan > 1.0 { 1.0 } else { pan }
  { buffer, offset_seconds: off, volume: vol, pan: p, mute: false, }
}

///|
/// Mutes or unmutes this track.
pub fn Track::set_mute(self : Track, mute : Bool) -> Unit {
  self.mute = mute
}

///|
/// Multi-track game audio mixer supporting polyphonic track scheduling,
/// stereo panning per track, and anti-clipping master soft limiting.
#derive(Eq)
pub struct Mixer {
  sample_rate : Int32
  tracks : Array[Track]
  mut master_volume : Double
}

///|
/// Creates an empty Mixer with the specified sample rate.
pub fn Mixer::new(sample_rate : Int32) -> Mixer {
  let sr = if sample_rate <= 0 { 44100 } else { sample_rate }
  { sample_rate: sr, tracks: [], master_volume: 1.0, }
}

///|
/// Adds an audio buffer to the mixer scheduled to start at `offset_seconds`
/// with individual volume and stereo pan (-1.0 to 1.0).
pub fn Mixer::add_track(
  self : Mixer,
  buffer : AudioBuffer,
  offset_seconds : Double,
  volume : Double,
  pan : Double,
) -> Unit {
  self.tracks.push(Track::new(buffer, offset_seconds, volume, pan))
}

///|
/// Sets the overall master volume of the mixer.
pub fn Mixer::set_master_volume(self : Mixer, vol : Double) -> Unit {
  self.master_volume = if vol < 0.0 { 0.0 } else { vol }
}

///|
/// Returns total duration of the mixed master output in seconds.
pub fn Mixer::duration(self : Mixer) -> Double {
  let mut max_dur = 0.0
  for i = 0; i < self.tracks.length(); i = i + 1 {
    let t = self.tracks[i]
    let track_end = t.offset_seconds + t.buffer.duration()
    if track_end > max_dur {
      max_dur = track_end
    }
  }
  max_dur
}

///|
/// Renders all scheduled tracks into a 2-channel StereoBuffer.
/// Implements Constant-Power Panning per track and master soft-limiting.
pub fn Mixer::render_stereo(self : Mixer) -> StereoBuffer {
  let sr_d = self.sample_rate.to_double()
  let total_dur = self.duration()
  let total_samples = (total_dur * sr_d).to_int()

  let left_samples = Array::make(total_samples, 0.0)
  let right_samples = Array::make(total_samples, 0.0)

  let pi_fourth = 3.141592653589793 / 4.0

  for t_idx = 0; t_idx < self.tracks.length(); t_idx = t_idx + 1 {
    let track = self.tracks[t_idx]
    if track.mute {
      continue
    }

    let offset_sample = (track.offset_seconds * sr_d).to_int()
    let (gain_l, gain_r) = if track.pan <= -0.9999 {
      (track.volume * self.master_volume, 0.0)
    } else if track.pan >= 0.9999 {
      (0.0, track.volume * self.master_volume)
    } else {
      let angle = (track.pan + 1.0) * pi_fourth
      (
        @math.cos(angle) * track.volume * self.master_volume,
        @math.sin(angle) * track.volume * self.master_volume,
      )
    }

    let t_samples = track.buffer.samples
    for i = 0; i < t_samples.length(); i = i + 1 {
      let target_idx = offset_sample + i
      if target_idx < total_samples {
        let s = t_samples[i]
        left_samples[target_idx] = left_samples[target_idx] + s * gain_l
        right_samples[target_idx] = right_samples[target_idx] + s * gain_r
      }
    }
  }

  let left_buf : AudioBuffer = {
    sample_rate: self.sample_rate,
    samples: left_samples,
  }
  let right_buf : AudioBuffer = {
    sample_rate: self.sample_rate,
    samples: right_samples,
  }

  // Apply master anti-clipping soft-limiting
  left_buf.soft_limit(0.85)
  right_buf.soft_limit(0.85)

  { sample_rate: self.sample_rate, left: left_buf, right: right_buf, }
}

///|
/// Renders all scheduled tracks into a mono AudioBuffer with master soft-limiting.
pub fn Mixer::render_mono(self : Mixer) -> AudioBuffer {
  let sr_d = self.sample_rate.to_double()
  let total_dur = self.duration()
  let total_samples = (total_dur * sr_d).to_int()

  let samples = Array::make(total_samples, 0.0)

  for t_idx = 0; t_idx < self.tracks.length(); t_idx = t_idx + 1 {
    let track = self.tracks[t_idx]
    if track.mute {
      continue
    }

    let offset_sample = (track.offset_seconds * sr_d).to_int()
    let track_gain = track.volume * self.master_volume
    let t_samples = track.buffer.samples

    for i = 0; i < t_samples.length(); i = i + 1 {
      let target_idx = offset_sample + i
      if target_idx < total_samples {
        samples[target_idx] = samples[target_idx] + t_samples[i] * track_gain
      }
    }
  }

  let buf : AudioBuffer = { sample_rate: self.sample_rate, samples, }
  buf.soft_limit(0.85)
  buf
}
