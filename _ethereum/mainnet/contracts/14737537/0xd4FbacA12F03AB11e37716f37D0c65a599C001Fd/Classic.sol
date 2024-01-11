// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20.sol";

contract Classic is ERC20 {
    constructor(uint256 _supply) ERC20("Classic", "CLAS") {
        _mint(msg.sender, _supply * (10 ** decimals()));
    }
}
