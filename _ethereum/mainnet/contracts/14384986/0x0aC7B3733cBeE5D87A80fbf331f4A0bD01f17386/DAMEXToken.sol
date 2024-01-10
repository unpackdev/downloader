// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";


contract DAMEXToken is ERC20 {
    constructor() ERC20("Damex Token", "DAMEX") {
        _mint(msg.sender, 370_000_000 ether);
    }
}
