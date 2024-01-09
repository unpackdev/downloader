// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";

/// @custom:security-contact security@plush.family
contract Plush is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Plush", "PLSH") ERC20Permit("Plush") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}
