// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";


contract MentalToken is ERC20 {
    constructor() ERC20("Mental Token", "MT") {
         _mint(msg.sender, 100000000 ether);
    }
}
