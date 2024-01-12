// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Pausable.sol";
import "./Ownable.sol";

contract PausableMint is Pausable, Ownable {
	/*
	 * Pause util functions
	 */
	function pauseMint() external onlyOwner {
		_pause();
	}

	function unpauseMint() external onlyOwner {
		_unpause();
	}
}
