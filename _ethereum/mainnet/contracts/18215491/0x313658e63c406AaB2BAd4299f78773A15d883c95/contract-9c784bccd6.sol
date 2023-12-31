// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC20.sol";

contract PEPEGAY is ERC20 {
    constructor() ERC20("PEPE GAY", "PEPE") {
        _mint(msg.sender, 420696969696969696 * 10**8);
    }
    function decimals() override public pure returns (uint8) {
        return 8;
    }
}
