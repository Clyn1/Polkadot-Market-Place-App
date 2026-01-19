[package]
name = "marketplace"
version = "1.0.0"
edition = "2021"
authors = ["Your Name <you@example.com>"]

[dependencies]
ink = { version = "6.0.0-beta.1", default-features = false }

# No more separate scale / scale-info needed – ink! re-exports them
# But if you need explicit versions:
scale = { package = "parity-scale-codec", version = "3", default-features = false, features = ["derive"] }
scale-info = { version = "2.11", default-features = false, features = ["derive"], optional = true }

[dev-dependencies]
ink_e2e = { version = "6.0.0-beta.1" }

# Sandbox moved to separate crate (not on crates.io yet)
ink_sandbox = { git = "https://github.com/use-ink/ink.git", branch = "6.0.0-beta.1" }

[lib]
path = "lib.rs"

[features]
default = ["std"]
std = [
    "ink/std",
    # remove old "scale/std", "scale-info/std" – ink! handles them
]
ink-as-dependency = []

[profile.release]
panic = "immediate-abort"
opt-level = "z"
lto = true
codegen-units = 1
overflow-checks = false