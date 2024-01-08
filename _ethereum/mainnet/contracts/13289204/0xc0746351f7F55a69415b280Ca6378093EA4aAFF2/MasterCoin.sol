// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./ERC20.sol";

contract MasterCoin is ERC20("MasterCoin", "$MASTER") {
    uint256 public constant TOTAL_SUPPLY = 100 * 1e18;

    constructor() {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}
