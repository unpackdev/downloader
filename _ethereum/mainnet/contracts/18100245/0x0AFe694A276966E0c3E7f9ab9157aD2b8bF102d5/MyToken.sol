// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("BidenShadowSnapeCatInu", "BSSCI") {
        _mint(msg.sender, 10000 ether);
    }
}
