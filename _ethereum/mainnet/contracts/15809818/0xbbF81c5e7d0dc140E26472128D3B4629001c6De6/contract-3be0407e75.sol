// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

contract THEInu is ERC20, ERC20Permit {
    constructor() ERC20("THE Inu", "THENU") ERC20Permit("THE Inu") {
        _mint(msg.sender, 500000000 * 10 ** decimals());
    }
}
