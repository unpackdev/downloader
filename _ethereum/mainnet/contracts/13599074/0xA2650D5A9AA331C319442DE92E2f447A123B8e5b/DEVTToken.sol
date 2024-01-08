// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";

contract DEVTToken is ERC20("DeHorizon Token", "DEVT") {

	constructor() public {
		_mint(msg.sender, 300_000_000 ether);
	}
}