// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20.sol";

contract GoldOfSkulls is ERC20 {
	constructor()
	ERC20("Gold of Skulls", "GSK") {
		_mint(
			msg.sender,
			10000000 * (10**uint256(decimals()))
		);
	}
}