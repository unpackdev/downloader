// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20PresetMinterPauser.sol";

contract Pump is ERC20PresetMinterPauser {
    constructor(address initialHolder, uint256 initialSupply) public ERC20PresetMinterPauser("Pump Token", "PUMP") {
        _mint(initialHolder, initialSupply);
    }
}