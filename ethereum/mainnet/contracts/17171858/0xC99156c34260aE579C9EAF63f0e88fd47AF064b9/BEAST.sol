// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact state@nwo.capital
contract ImageOfTheBeast is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Image of the Beast", "BEAST") {
        _mint(msg.sender, 299792458 * 10 ** decimals());
    }
}