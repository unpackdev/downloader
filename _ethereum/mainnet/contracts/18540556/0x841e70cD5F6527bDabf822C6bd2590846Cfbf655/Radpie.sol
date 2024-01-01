// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

/// @title MGP
/// @author Magpie Team
contract Radpie is ERC20('Radpie Token', 'RDP'), ERC20Permit('Radpie Token') {
    constructor(address _receipient, uint256 _totalSupply) {
        _mint(_receipient, _totalSupply);
    }
}