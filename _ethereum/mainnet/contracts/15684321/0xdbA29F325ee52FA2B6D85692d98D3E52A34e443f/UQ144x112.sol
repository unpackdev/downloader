// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**144 - 1]
// resolution: 1 / 2**112

library UQ144x112
{
	uint256 private constant _Q112 = 2**112;

	// encode a uint112 as a UQ144x112
	function encode(uint112 y) internal pure returns (uint256)
	{
		unchecked
		{
			return uint256(y) * _Q112; // never overflows
		}
	}

	// divide a UQ144x112 by a uint112, returning a UQ144x112
    function uqdiv(uint256 x, uint112 y) internal pure returns (uint256)
	{
        return x / uint256(y);
    }
}