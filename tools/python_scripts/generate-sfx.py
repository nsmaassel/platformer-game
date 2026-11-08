## generate-sfx.py — Procedural 8-bit Sound Effects Generator
## Uses Python standard library (wave, math, struct) to generate retro chiptune sound effects.
import math
import os
import struct
import sys
import wave
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

SAMPLE_RATE = 44100
OUT_DIR = Path("assets/sfx")


def ensure_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)


def write_wav(filename: str, samples: list[float]):
    """Write 16-bit mono WAV file."""
    ensure_dir(OUT_DIR)
    file_path = OUT_DIR / filename
    with wave.open(str(file_path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        packed = []
        for s in samples:
            # Clamp sample to [-1.0, 1.0]
            val = max(-1.0, min(1.0, s))
            sample_16bit = int(val * 32767)
            packed.append(struct.pack("<h", sample_16bit))
        wf.writeframes(b"".join(packed))
    print(f"  🔊 Generated: {file_path}")


def square_wave(freq: float, t: float) -> float:
    return 1.0 if (t * freq) % 1.0 < 0.5 else -1.0


def triangle_wave(freq: float, t: float) -> float:
    phase = (t * freq) % 1.0
    return 4.0 * abs(phase - 0.5) - 1.0


def noise_sample() -> float:
    import random
    return random.uniform(-1.0, 1.0)


def gen_jump():
    """Jump SFX: pitch sweep up 150Hz -> 450Hz."""
    duration = 0.15
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        freq = 150.0 + progress * 300.0
        env = 1.0 - progress
        phase += freq / SAMPLE_RATE
        s = square_wave(1.0, phase) * 0.3 * env
        samples.append(s)
    write_wav("jump.wav", samples)


def gen_coin():
    """Coin SFX: two-tone chime (B5 -> E6)."""
    duration = 0.18
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        freq = 987.77 if progress < 0.4 else 1318.51
        env = 1.0 - progress
        phase += freq / SAMPLE_RATE
        s = (0.7 * square_wave(1.0, phase) + 0.3 * triangle_wave(1.0, phase)) * 0.35 * env
        samples.append(s)
    write_wav("coin.wav", samples)


def gen_stomp():
    """Stomp SFX: impact noise + pitch drop."""
    import random
    random.seed(42)
    duration = 0.12
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        freq = 280.0 - progress * 200.0
        env = (1.0 - progress) ** 2
        phase += freq / SAMPLE_RATE
        s = (0.5 * square_wave(1.0, phase) + 0.5 * noise_sample()) * 0.4 * env
        samples.append(s)
    write_wav("stomp.wav", samples)


def gen_checkpoint():
    """Checkpoint SFX: ascending arpeggio chord."""
    duration = 0.35
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes = [523.25, 659.25, 783.99, 1046.50]  # C5, E5, G5, C6
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        note_idx = min(int(progress * 4), 3)
        freq = notes[note_idx]
        env = 1.0 - (progress % 0.25) * 2.0
        env = max(0.2, env)
        phase += freq / SAMPLE_RATE
        s = square_wave(1.0, phase) * 0.3 * env * (1.0 - progress * 0.5)
        samples.append(s)
    write_wav("checkpoint.wav", samples)


def gen_hurt():
    """Hurt SFX: buzzing low pitch drop."""
    duration = 0.25
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        freq = 200.0 - progress * 140.0
        env = 1.0 - progress
        phase += freq / SAMPLE_RATE
        s = (square_wave(1.0, phase) + noise_sample() * 0.3) * 0.35 * env
        samples.append(s)
    write_wav("hurt.wav", samples)


def gen_win():
    """Level clear SFX: victory jingle."""
    duration = 0.5
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes = [523.25, 659.25, 783.99, 1046.50, 1318.51]  # C5, E5, G5, C6, E6
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        note_idx = min(int(progress * 5), 4)
        freq = notes[note_idx]
        env = 1.0 - (progress * 0.6)
        phase += freq / SAMPLE_RATE
        s = square_wave(1.0, phase) * 0.35 * env
        samples.append(s)
    write_wav("win.wav", samples)


def gen_powerup():
    """Powerup SFX: bright ascending synth chime."""
    duration = 0.4
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    notes = [783.99, 987.77, 1174.66, 1567.98]  # G5, B5, D6, G6
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        note_idx = min(int(progress * 4), 3)
        freq = notes[note_idx]
        env = 1.0 - (progress % 0.25) * 1.5
        env = max(0.3, env)
        phase += freq / SAMPLE_RATE
        s = (0.7 * square_wave(1.0, phase) + 0.3 * triangle_wave(1.0, phase)) * 0.35 * env
        samples.append(s)
    write_wav("powerup.wav", samples)


def gen_hit():
    """Hit SFX: fast noise burst + low crunch."""
    import random
    duration = 0.12
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        freq = 320.0 - progress * 240.0
        env = (1.0 - progress) ** 1.5
        phase += freq / SAMPLE_RATE
        s = (0.4 * square_wave(1.0, phase) + 0.6 * noise_sample()) * 0.4 * env
        samples.append(s)
    write_wav("hit.wav", samples)


def gen_laser():
    """Laser SFX: rapid descending pitch chirp."""
    duration = 0.14
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        freq = 1400.0 * math.exp(-progress * 4.0) + 120.0
        env = 1.0 - progress
        phase += freq / SAMPLE_RATE
        s = square_wave(1.0, phase) * 0.3 * env
        samples.append(s)
    write_wav("laser.wav", samples)


def gen_explosion():
    """Explosion SFX: bass rumble + disintegrating white noise."""
    duration = 0.45
    total_samples = int(SAMPLE_RATE * duration)
    samples = []
    phase = 0.0
    for i in range(total_samples):
        progress = i / total_samples
        freq = 80.0 * (1.0 - progress * 0.7)
        env = (1.0 - progress) ** 1.8
        phase += freq / SAMPLE_RATE
        s = (0.3 * triangle_wave(1.0, phase) + 0.7 * noise_sample()) * 0.45 * env
        samples.append(s)
    write_wav("explosion.wav", samples)


def main():
    print("🔊 Synthesizing procedural 8-bit sound effects...")
    gen_jump()
    gen_coin()
    gen_stomp()
    gen_checkpoint()
    gen_hurt()
    gen_win()
    gen_powerup()
    gen_hit()
    gen_laser()
    gen_explosion()
    print("✅ All SFX generated in assets/sfx/")



if __name__ == "__main__":
    main()
