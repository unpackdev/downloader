// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./ERC20.sol";


contract MockToken is ERC20 {
    constructor(uint256 initialBalance) ERC20("MockToken", "MOCK") public {
        _mint(msg.sender, initialBalance);
    }
}
