// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SHEPE2 is ERC20 {
    constructor() ERC20("SHEPE2", "Shia Vs Pepe2") {
        uint256 tokenSupply = 1000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
