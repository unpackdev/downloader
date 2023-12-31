// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";


contract DevToken is ERC20{
    constructor() ERC20("Tether USD", "USDT"){
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
    function decimals() override public pure returns (uint8) {
        return 8;
    }
}