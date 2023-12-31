// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

/// @title MGP
/// @author Magpie Team
contract MGP is ERC20('Magpie Token', 'MGP'), ERC20Permit('Magpie Token') {
    constructor(address _receipient, uint256 _totalSupply) {
        _mint(_receipient, _totalSupply);
    }
}