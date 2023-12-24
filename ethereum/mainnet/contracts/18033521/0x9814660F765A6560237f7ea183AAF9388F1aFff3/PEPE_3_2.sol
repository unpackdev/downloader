// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://twitter.com/PepeCommunity_
// https://t.me/PepeCommunityEntry


import "./ERC20.sol";

contract Pepe_3_2 is ERC20 {
    constructor() ERC20("PEPE32", "Pepe3.2") {
        uint256 tokenSupply = 1000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}
