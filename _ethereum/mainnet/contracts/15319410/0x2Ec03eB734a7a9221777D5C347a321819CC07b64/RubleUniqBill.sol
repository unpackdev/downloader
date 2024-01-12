// SPDX-License-Identifier: MIT

// RubleUniqBill project token ERC20

//***************************************************************
// ERC20 part of this contract based on best community practice 
// of https://github.com/OpenZeppelin/zeppelin-solidity
// Adapted and amended by IBERGroup, email:maxsizmobile@iber.group; 
// Code released under the MIT License.
////**************************************************************

pragma solidity 0.8.13;

import "ERC20.sol";

contract RubleUniqBill is ERC20 {

    uint256 constant public MAX_SUPPLY = 1_000_000_000e18;

    constructor(address initialKeeper)
    ERC20("Ruble Unique Bill", "RUB")
    { 
        _mint(initialKeeper, MAX_SUPPLY);
    }
}

