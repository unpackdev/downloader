// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract BTZ is ERC20, Ownable {

    constructor() ERC20("Bitazza Token", "BTZ") {
		_mint(msg.sender, 3000000000 * 10**18);
	}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

}
