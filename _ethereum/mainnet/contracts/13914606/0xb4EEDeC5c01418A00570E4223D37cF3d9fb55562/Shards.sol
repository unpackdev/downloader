// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Shards is ERC20 {
    constructor() ERC20("Andrometa Shards", "ADS") {
		_mint(msg.sender, 250000000 * 10**18);
	}
}
