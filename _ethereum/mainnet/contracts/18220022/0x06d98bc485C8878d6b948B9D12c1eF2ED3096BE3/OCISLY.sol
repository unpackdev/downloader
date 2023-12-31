// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract OCISLY is ERC20 {
    constructor() ERC20(unicode"OCISLY", unicode"Of Course I Still Love You") {
        uint256 tokenSupply = 42069000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
