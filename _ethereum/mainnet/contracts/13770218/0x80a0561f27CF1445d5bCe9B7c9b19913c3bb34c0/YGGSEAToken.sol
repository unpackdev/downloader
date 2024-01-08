// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ERC20.sol";

contract YGGSEAToken is ERC20("YGG SEA Token", "SEA") {
    constructor() public {
		_mint(msg.sender, 1_000_000_000 ether);
	}
}
