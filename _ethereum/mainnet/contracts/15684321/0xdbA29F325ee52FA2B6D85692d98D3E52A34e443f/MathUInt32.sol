// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MathUInt32
{
	function unsafeSub32(uint32 a, uint32 b) internal pure returns (uint32)
	{
		unchecked
		{
			return a - b;
		}
	}
}