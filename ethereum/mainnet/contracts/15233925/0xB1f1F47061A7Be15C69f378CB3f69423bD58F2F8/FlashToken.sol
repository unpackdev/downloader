// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";

contract FlashToken is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Flashstake", "FLASH") ERC20Permit("Flashstake") {
        _mint(msg.sender, 150000000 * 10**decimals());
    }
}
