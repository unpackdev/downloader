// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";

/// @custom:security-contact support@mazuri.io
contract MAZURI is ERC20, ERC20Burnable, AccessControl {
    constructor() ERC20("MAZURI", "MZR") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
