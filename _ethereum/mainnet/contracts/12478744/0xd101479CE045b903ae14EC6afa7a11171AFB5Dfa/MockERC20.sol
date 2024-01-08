// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";

contract MockERC20 is ERC20 {
	uint256 public totalSupply;

	constructor(
		string memory _name,
		string memory _symbol,
		uint256 _initialAmount
	) public ERC20(_name, _symbol) {
		// Give the creator all initial tokens
		balanceOf[msg.sender] = _initialAmount;
		// Update total supply
		totalSupply = _initialAmount;
	}

	function mint(address account, uint256 amount) external {
		require(account != address(0), "MockERC20::mint: mint to the zero address");

		totalSupply += amount;
		balanceOf[account] += amount;

		emit Transfer(address(0), account, amount);
	}
}
