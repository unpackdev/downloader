// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ERC20.sol";

/*
 *  @title Wildland's Token
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

contract BitGold is ERC20("Bitgold", "BTG"), Ownable {

    constructor(address treasury) {
        _mint(treasury, 11e6 * 10 ** decimals());
    }
}
