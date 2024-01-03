// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.1;

import "./ERC20Burnable.sol";


contract GamerCoin is ERC20Burnable {
    constructor(uint256 initialBalance) ERC20("GHTEST", "GTT") {
        _mint(msg.sender, initialBalance);
    }
}
