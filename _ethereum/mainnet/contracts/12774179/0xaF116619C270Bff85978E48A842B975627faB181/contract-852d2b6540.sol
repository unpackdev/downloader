// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract FujiToken is ERC20, ERC20Burnable {
    constructor(address to) ERC20("36 BLOCKS OF FUJI", "FUJI") {
        _mint(to, 37760000 * 10 ** decimals());
    }
}
