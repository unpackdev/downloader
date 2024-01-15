// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";

contract Cryptoken is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Cryptoken", "CRTKN") ERC20Permit("Cryptoken") {
        _mint(msg.sender, 10_000_000 * 10 ** decimals());
    }
}