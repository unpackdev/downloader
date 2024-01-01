/**
 *  __  __ _  _ _  ____   __
 * |  \/  | \| | |/ /\ \ / /
 * | |\/| | .` | ' <  \ V / 
 * |_|  |_|_|\_|_|\_\  |_|     
 * 	  https://mnky.vip 
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";

/// @custom:security-contact mod@mnky.vip
contract MNKY is ERC20, ERC20Permit {
    constructor() ERC20("MNKY Coin", "MNKY") ERC20Permit("MNKY Coin") {
        _mint(msg.sender, 21_420_690_000 * 10 ** decimals());
    }
}