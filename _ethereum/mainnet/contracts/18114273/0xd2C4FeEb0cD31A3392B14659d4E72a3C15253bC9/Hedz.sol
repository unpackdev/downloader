/*
https://hottiefroggie.co
https://t.me/HottieFroggieEntry
https://twitter.com/HEDZ_COIN
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract HottieFroggie is ERC20 {
    constructor() ERC20("Hottie Froggie", "Hedz") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}