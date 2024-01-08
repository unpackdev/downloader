// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";

contract UzmiToken is ERC20, AccessControl {
    constructor() ERC20("Uzmi Token", "UZMI") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}

