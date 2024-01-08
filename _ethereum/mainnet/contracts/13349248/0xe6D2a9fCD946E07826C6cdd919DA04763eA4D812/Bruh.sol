// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./ERC20.sol";

contract Bruh is ERC20 {
    constructor() public ERC20("Bruh", "BRUH"){
        _mint(msg.sender, 2000000000000000000000000000);
    }
}
