// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./Ownable.sol";

contract BlockBank is ERC20("BlockBank", "BBANK"), Ownable {
    
    uint public constant TOTAL_SUPPLY = 400000000 * (10 ** 18);
    
    constructor() public {    
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}