// SPDX-License-Identifier: HITLERS DOGGO
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

/// @custom:security-contact HITLERDOGGO@HITLER.FUHER
contract BLONDI is ERC20, ERC20Burnable {
    constructor() ERC20("BLONDI", "BLONDI DOG") {
        _mint(msg.sender, 6900000000000 * 10 ** decimals());
    }
}
