// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract GreateTicket is ERC20 {
    constructor() ERC20("Greate Ticket", "GTT") {
        _mint(msg.sender, 100000000000);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 2;
    }
}