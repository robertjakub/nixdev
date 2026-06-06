import type { NextConfig } from "next";
import { execSync } from "child_process";

const nextConfig: NextConfig = {
	output: "standalone",
	generateBuildId: async () => {
		// Get tag of current branch(that is HEAD) or fallback to short commit hash (7 digits)
		return "nixpkgs";
	},
};

export default nextConfig;
