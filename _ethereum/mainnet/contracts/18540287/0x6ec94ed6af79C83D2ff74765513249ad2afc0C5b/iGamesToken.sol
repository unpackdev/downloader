// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract IGST is ERC20 {
    constructor() ERC20("iGames Token", "IGST") {
        _mint(msg.sender, 1_300_000_000 ether);
    }
}
