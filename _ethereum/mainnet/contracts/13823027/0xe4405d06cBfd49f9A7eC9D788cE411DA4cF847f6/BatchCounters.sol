// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BatchCounters {
	struct Counter {
		uint256 _value; // default: 0
	}

	function current(Counter storage counter) internal view returns (uint256) {
		return counter._value;
	}

	function increment(Counter storage counter, uint256 amount) internal returns (uint256 start, uint256 end) {
		start = counter._value + 1;
		counter._value += amount;
		end = counter._value;
	}
}
