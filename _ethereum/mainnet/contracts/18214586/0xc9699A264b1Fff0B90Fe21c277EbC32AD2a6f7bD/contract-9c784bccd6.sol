// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract ElonToken is ERC20 {
    constructor() ERC20("ELON Coin", "ELON") {
        _mint(msg.sender, 111111111111111111 * 10**8);
    }
    function decimals() override public pure returns (uint8) {
        return 8;
    }
}
