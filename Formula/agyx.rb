# frozen_string_literal: true

# This file is published in the tap repository iamdin/homebrew-tap (Formula/agyx.rb).
class Agyx < Formula
  desc "Run several Google Antigravity (agy) CLI profiles side by side"
  homepage "https://github.com/iamdin/agyx"
  url "https://github.com/iamdin/agyx/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "2ea925c3a4ab6be5b5991555ef17f57edc87faa2ed20801e53d6e4eabe3e680b"
  license "MIT"

  def install
    # The scripts find their siblings (agy shim, runtime/) by resolving their own real path, so
    # keep bin/ and runtime/ together in libexec and expose only agyx. They store the
    # opt_prefix path (not this versioned Cellar directory) wherever a path must survive upgrades.
    libexec.install "bin", "runtime"
    bin.install_symlink libexec/"bin/agyx"
  end

  test do
    assert_match "agyx #{version}", shell_output("#{bin}/agyx --version")
    # misuse of a management subcommand prints the usage and exits 2
    assert_match "usage: agyx", shell_output("#{bin}/agyx profile list extra 2>&1", 2)
    assert_path_exists libexec/"bin/agy"
    refute_path_exists bin/"agy"

    # no setup step: the real agy comes from AGYX_REAL_AGY (no real agy is run), the
    # <data>/bin/agy entry and the symlinks file are created by the first run
    ENV["AGYX_DATA_DIR"] = testpath/"data"
    ENV["AGYX_REAL_HOME"] = testpath
    ENV["AGYX_REAL_AGY"] = "/usr/bin/true"
    ENV["AGYX_ASSUME_YES"] = "1" # skip the first-run question
    (testpath/"data/profiles/work/home").mkpath
    # anything that is not an agyx subcommand launches agy via the shim
    system bin/"agyx", "--profile", "work"
    # the entry link goes through opt_prefix, so it survives upgrades
    assert_equal opt_libexec/"bin/agy", Pathname(File.readlink(testpath/"data/bin/agy"))
    assert_path_exists testpath/".config/agyx/symlinks"
  end
end
