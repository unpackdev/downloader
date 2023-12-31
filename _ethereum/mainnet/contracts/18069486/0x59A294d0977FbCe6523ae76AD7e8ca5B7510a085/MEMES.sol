// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract MEMES is ERC20 {
    constructor() ERC20(unicode"M三M三S", unicode"M三M三S") {
        uint256 tokenSupply = 1000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
