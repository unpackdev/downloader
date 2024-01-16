// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

/// @custom:security-contact LFETA@meta.com
contract LightFeta is ERC20, ERC20Burnable {
    constructor() ERC20("LightFeta", "LFETA") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}