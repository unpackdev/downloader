// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./Ownable.sol";

contract TheBitGold is ERC20, Ownable {
    constructor(address to_) ERC20("TheBitGold", "BGT") {
        _mint(to_, 10000000 * 10 ** decimals());
    }
}