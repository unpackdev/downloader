// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MathUInt256
{
	function min(uint256 a, uint256 b) internal pure returns(uint256)
	{
		return a > b ? b : a;
	}

	// solhint-disable-next-line code-complexity
	function sqrt(uint256 x) internal pure returns (uint256)
	{
		if (x == 0)
		{
			return 0;
		}

		// Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
		uint256 xAux = x;
		uint256 result = 1;
		if (xAux >= 0x100000000000000000000000000000000)
		{
			xAux >>= 128;
			result <<= 64;
		}
		if (xAux >= 0x10000000000000000)
		{
			xAux >>= 64;
			result <<= 32;
		}
		if (xAux >= 0x100000000)
		{
			xAux >>= 32;
			result <<= 16;
		}
		if (xAux >= 0x10000)
		{
			xAux >>= 16;
			result <<= 8;
		}
		if (xAux >= 0x100)
		{
			xAux >>= 8;
			result <<= 4;
		}
		if (xAux >= 0x10)
		{
			xAux >>= 4;
			result <<= 2;
		}
		if (xAux >= 0x4)
		{
			result <<= 1;
		}

		// The operations can never overflow because the result is max 2^127 when it enters this block.
		unchecked
		{
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1; // Seven iterations should be enough
			uint256 roundedDownResult = x / result;
			return result >= roundedDownResult ? roundedDownResult : result;
		}
	}

	function unsafeDec(uint256 a) internal pure returns (uint256)
	{
		unchecked 
		{
			return a - 1;
		}
	}

	function unsafeDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		unchecked
		{
			return a / b;
		}
	}

	function unsafeInc(uint256 a) internal pure returns (uint256)
	{
		unchecked 
		{
			return a + 1;
		}
	}

	function unsafeMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		unchecked
		{
			return a * b;
		}
	}

	function unsafeSub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		unchecked
		{
			return a - b;
		}
	}
}