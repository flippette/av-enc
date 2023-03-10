#![feature(if_let_guard, let_chains)]

use camino::{Utf8Path, Utf8PathBuf};
use eyre::{eyre, Result};
use glob::glob;
use std::{
    env,
    process::{Command, Stdio},
    thread,
};
use tracing::{info, warn};

fn main() -> Result<()> {
    color_eyre::install()?;
    tracing_subscriber::fmt()
        .compact()
        .try_init()
        .map_err(|e| eyre!("failed to initialize logging: {e:?}"))?;

    let threads = thread::available_parallelism()?.get();

    for path in env::args()
        .skip(1)
        .flat_map(|arg| glob(&arg))
        .flat_map(|p| p.into_iter())
    {
        let path = match path {
            Ok(p) => match Utf8PathBuf::try_from(p) {
                Ok(pb) if let Ok(cpb) = pb.canonicalize_utf8() && cpb.is_file() => {
                    info!("encoding file {pb}.");
                    cpb
                }
                Ok(pb) if pb.is_dir() => continue,
                Ok(pb) => {
                    warn!("path {pb} does not exist, skipping.");
                    continue;
                }
                Err(e) => {
                    warn!(
                        "failed to parse path {} with error {e:?}, skipping.",
                        e.as_path().display(),
                    );

                    continue;
                }
            },
            Err(e) => {
                warn!(
                    "failed to glob path {} with error {e:?}, skipping.",
                    e.path().display(),
                );
                continue;
            }
        };

        let stem = path.file_stem().unwrap_or_default();
        let ext = path.extension().unwrap_or_default();

        let framerate = {
            let query_result = ffprobe_query(&path, "v", "avg_frame_rate")?;
            let mut tokens = query_result.split('/');

            tokens.next().unwrap().parse::<f64>()?
                / tokens.next().unwrap().parse::<f64>().unwrap_or(1.0)
        };

        info!("searching for optimal crf...");
        let crf = crf_query(&path)?;

        info!("crf search complete, encoding...");
        Command::new("ffmpeg")
            .arg("-y")
            .args(["-hwaccel", "auto"])
            .args(["-i", path.as_ref()])
            .args(["-pix_fmt", "yuv420p10le"])
            .args(["-c:v", "libsvtav1"])
            .args([
                "-svtav1-params",
                &[
                    "preset=4",
                    "profile=0",
                    "input-depth=10",
                    &format!("lp={threads}"),
                    &format!("pin={threads}"),
                    &format!("crf={crf}"),
                    "aq-mode=1",
                    "enable-qm=1",
                    &format!("keyint={}", framerate * 10.0),
                    "irefresh-type=2",
                    "scd=1",
                    "lookahead=120",
                    "enable-tf=0",
                    "enable-overlays=1",
                    "tune=0",
                ]
                .join(":"),
            ])
            .args(["-c:a", "libopus"])
            .args(["-b:a", "128k"])
            .args(["-map", "0:v"])
            .args(["-map", "0:a:m:language:jpn"])
            .args(["-map", "0:s:m:language:eng"])
            .arg(format!("{}/{stem}.op.{ext}", path.parent().unwrap()))
            .spawn()?
            .wait()?;
    }

    Ok(())
}

fn ffprobe_query(file: &Utf8Path, stream: &str, entry: &str) -> Result<String> {
    String::from_utf8(
        Command::new("ffprobe")
            .args(["-loglevel", "panic"])
            .args(["-select_streams", stream])
            .args(["-show_entries", &format!("stream={entry}")])
            .arg(file)
            .output()
            .unwrap()
            .stdout,
    )?
    .lines()
    .find(|line| line.starts_with(entry))
    .ok_or(eyre!("property query on {file} failed: not found"))?
    .split('=')
    .last()
    .ok_or(eyre!("property query on {file} failed: parse failure"))
    .map(String::from)
}

fn crf_query(file: &Utf8Path) -> Result<u32> {
    let ab_err = || eyre!("crf query on {file} failed: failed to parse ab-av1 output");

    String::from_utf8(
        Command::new("ab-av1")
            .arg("crf-search")
            .args(["-e", "libsvtav1"])
            .args(["-i", file.as_ref()])
            .args(["--pix-format", "yuv420p10le"])
            .args(["--min-vmaf", "92"])
            .args(["--min-samples", "2"])
            .args(["--vmaf-scale", "none"])
            .args(["--preset", "5"])
            .args(["--keyint", "10s"])
            .args(["--scd", "true"])
            .args([
                "--svt",
                &[
                    "tune=0",
                    "enable-overlays=1",
                    "enable-tf=0",
                    "lookahead=120",
                    "irefresh-type=2",
                    "enable-qm=1",
                    "aq-mode=1",
                    "input-depth=10",
                    "profile=0",
                ]
                .join(":"),
            ])
            .args(["--cache", "false"])
            .args([
                "--temp-dir",
                &format!(
                    "{}/.tmp.{}",
                    file.parent().map(|p| p.as_ref()).unwrap_or("/"),
                    file.file_stem().unwrap_or("")
                ),
            ])
            .stdout(Stdio::piped())
            .spawn()?
            .wait_with_output()?
            .stdout,
    )?
    .lines()
    .find(|line| line.starts_with("crf"))
    .ok_or_else(ab_err)?
    .split_whitespace()
    .nth(1)
    .ok_or_else(ab_err)?
    .parse()
    .map_err(|e| eyre!("crf query on {file} failed: {e:?}"))
}
