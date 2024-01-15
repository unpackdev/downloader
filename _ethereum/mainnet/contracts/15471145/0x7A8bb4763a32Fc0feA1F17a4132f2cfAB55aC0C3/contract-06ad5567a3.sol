// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20FlashMint.sol";

/// @custom:security-contact support@poorpleb.win
contract PoorPleb is ERC20, ERC20Burnable, ERC20FlashMint {
    constructor() ERC20("PoorPleb", "PP") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}
