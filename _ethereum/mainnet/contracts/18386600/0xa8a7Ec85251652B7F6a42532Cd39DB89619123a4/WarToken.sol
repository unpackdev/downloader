// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";

contract WarToken is ERC20 {
    constructor() ERC20("War", "WAR") {
        _mint(msg.sender, 14000000000000 * 10**8);
    }
    function decimals() override public pure returns (uint8) {
        return 8;
    }
}
