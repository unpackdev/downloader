// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "./ERC20Permit.sol";
import "./ERC20Burnable.sol";

contract YIELDToken is ERC20Permit, ERC20Burnable {
    //total fixed supply of 140,736,000 tokens.

    constructor () ERC20Permit("Yield Protocol") ERC20("Yield Protocol", "YIELD") {
        super._mint(msg.sender, 140736000 ether);
    }
}
