// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------
// Xorshift

library Random {
	struct Status {
		uint256 x;
		uint256 y;
		uint256 z;
		uint256 w;
	}

	function init(Status memory status, uint256 seed) internal pure {
		status.x = 123456789;
		status.y = 362436069;
		status.z = 521288629;
		status.w = 88675123;
		status.w ^= seed;
	}

	function get(Status memory status) internal pure returns (uint256) {
		uint256 x = status.x;
		uint256 w = status.w;
		uint256 t = (x ^ (x << 11));
		status.x = status.y;
		status.y = status.z;
		status.z = status.w;
		status.w = (w ^ (w >> 19)) ^ (t ^ (t >> 8));
		return status.w;
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

