// contracts/ERC-20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./console.sol";

contract ADORAToken is ERC20 {
	uint256 constant supply = 888714888* 10**18;

	constructor() public ERC20("Adora", "ARA") {
		console.log("Minting supply", supply, "and assigning to:", msg.sender);
		_mint(msg.sender, supply);
	}
}
