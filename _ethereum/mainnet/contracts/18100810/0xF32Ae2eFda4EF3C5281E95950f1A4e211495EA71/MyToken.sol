// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("HedgeHogBucks", "HHB") {
        _mint(msg.sender, 1000000 ether);
    }
}
