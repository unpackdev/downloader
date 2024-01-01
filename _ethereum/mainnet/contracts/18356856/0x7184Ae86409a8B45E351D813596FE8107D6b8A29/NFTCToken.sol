// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract NFTCToken is ERC20 {
    uint256 private constant TOTAL_SUPPLY = 500_000_000_000;

    constructor() ERC20("NFTrium Collective", "NFTC") {
        _mint(msg.sender, TOTAL_SUPPLY * (10 ** decimals()));
    }
}
