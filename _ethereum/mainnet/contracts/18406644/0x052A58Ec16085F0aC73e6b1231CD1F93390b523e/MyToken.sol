// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit {
    constructor() ERC20("Tether USD", "USDT") ERC20Permit("USDT") {
        _mint(msg.sender,1500000000*10**18);
    }
}

 