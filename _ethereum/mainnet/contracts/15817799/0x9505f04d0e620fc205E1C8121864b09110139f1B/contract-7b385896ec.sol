// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

/// @custom:security-contact apetheshape@protonmail.com
contract NOTHING is ERC20, Ownable {
    constructor() ERC20("NOTHING", "NOTHING") {
        _mint(msg.sender, 1 * 10 ** decimals());
    }
}
