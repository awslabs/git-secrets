# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class GitSecrets < Formula
	desc "Prevents you from committing secrets and credentials into git repositories"
	homepage ""
	url "https://github.com/Smarsh/git-secrets/archive/v1.3.1.tar.gz"
	sha256 "476c9e82cc8cbe6957cee6a07fa4d94213b4b3b881d27444dc12560b8c40c619"
	# depends_on "cmake" => :build
	def install
	  # ENV.deparallelize  # if your formula fails when building in parallel
	  # Remove unrecognized options if warned by configure
	  system "./configure", "--disable-debug",
							"--disable-dependency-tracking",
							"--disable-silent-rules",
							"--prefix=#{prefix}"
	  # system "cmake", ".", *std_cmake_args
	end
	test do
	  # `test do` will create, run in and delete a temporary directory.
	  #
	  # This test will fail and we won't accept that! For Homebrew/homebrew-core
	  # this will need to be a test that verifies the functionality of the
	  # software. Run the test with `brew test git-secrets`. Options passed
	  # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
	  #
	  # The installed folder is not in the path, so use the entire path to any
	  # executables being tested: `system "#{bin}/program", "do", "something"`.
	  system "false"
	end
end