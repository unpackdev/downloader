// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";

/// @custom:security-contact security@wirk.world
contract W1RK is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("W1RK", "W1RK") ERC20Permit("W1RK") {
        _mint(msg.sender, 7000000000 * 10 ** decimals());
    }
}
