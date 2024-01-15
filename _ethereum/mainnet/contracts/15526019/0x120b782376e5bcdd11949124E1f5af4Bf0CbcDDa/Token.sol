// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token is ERC20{
    constructor() ERC20("TestToken", "TestT"){
        _mint(msg.sender,1000*10**18);
    }
}