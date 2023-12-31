// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract FWEN is ERC20 {
    constructor(uint256 supply) ERC20("FWEN", "FWEN") {
        _mint(msg.sender, supply);
    }
}
