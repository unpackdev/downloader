// SPDX-License-Identifier: MIT
// (C) by TokenForge GmbH, Berlin
// Author: Hagen Hübel, hagen@token-forge.io
pragma solidity ^0.8.7;

import "./ERC20Capped.sol";
import "./Ownable.sol";

contract FutureOfMusic01 is ERC20Capped, Ownable {
    constructor() ERC20("FutureOfMusic01", "FOM-01") ERC20Capped(50 ether) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
