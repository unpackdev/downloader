// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./SafeMath.sol";

interface IUTUToken {
	function mint(address to, uint256 amount) external;
	function burn(uint256 amount) external;
}

contract Distributor is Ownable {
	using SafeMath for uint256;

	// Use a global counter so batches when distributing cannot overlap.
	uint256 private idx;

	address public utuToken;
	uint256 public toMint;
	uint256 public distributeAfter;
	bool public assigned;

	struct Contributor {
		address addr;
		uint256 amount;
	}

	Contributor[] public contribs;

	constructor(
		address _utuToken,
		uint256 _toMint,
		uint256 _distributeAfter
	) public {
		utuToken = _utuToken;
		toMint = _toMint;
		distributeAfter = _distributeAfter;
	}

	function assign(
		address[] memory _contributors,
		uint256[] memory _balances
	) onlyOwner public {
		require(!assigned, "UTU: assigned");
		require(_contributors.length == _balances.length, "UTU: mismatching array lengths");
		for (uint32 i = 0 ; i < _contributors.length; i++) {
			Contributor memory c = Contributor(_contributors[i], _balances[i]);
			toMint = toMint.sub(c.amount); // Will throw on underflow
			contribs.push(c);
		}
	}

	function assignDone() onlyOwner public {
		assigned = true;
	}

	function distribute(uint256 _to) public {
		require(assigned, "UTU: !assigned");
		require(block.timestamp > distributeAfter, "UTU: still locked");
		require(_to < contribs.length, "UTU: out of range");
		for (; idx <= _to; idx++) {
			IUTUToken(utuToken).mint(contribs[idx].addr, contribs[idx].amount);
		}
	}
}
