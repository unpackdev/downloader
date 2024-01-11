// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract USDF is ERC20, Ownable {

    constructor() ERC20("USD Freedom", "USDF") {
		_mint(msg.sender, 10000000 * 10**18);
	}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

}
