// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title The Nuon implementation that uses burn/mint to bridge
 * @author Doggo
 */
contract BridgedNuon is ERC20, Ownable {
	/**
	 * Errors
	 */

	error NotAuthorized();

	/**
	 * Storage
	 */

	mapping(address => bool) private _isAllowedToMint;

	/**
	 * Constructor
	 */

	constructor() ERC20("NUON", "NUON") {}

	/**
	 * Non-View functions
	 */

	function mint(address to, uint256 amount) external {
		if (_isAllowedToMint[msg.sender] == false) revert NotAuthorized();
		_mint(to, amount);
	}

	function burn(address from, uint256 amount) external {
		_spendAllowance(from, msg.sender, amount);
		_burn(from, amount);
	}

	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
	}

	/**
	 * View Functions
	 */

	function isAllowedToMint(address minter) external view returns (bool) {
		return _isAllowedToMint[minter];
	}

	/**
	 * Owner Functions
	 */

	function setIsAllowedToMint(address minter, bool allowed) external onlyOwner {
		_isAllowedToMint[minter] = allowed;
	}
}
