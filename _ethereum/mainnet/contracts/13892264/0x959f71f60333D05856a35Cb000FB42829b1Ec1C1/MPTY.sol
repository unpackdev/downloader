// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";

contract MPTY is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Matic-PTY", "MPTY") ERC20Permit("Matic-PTY") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
