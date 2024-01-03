// contracts/FortuneLuck.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract FortuneLuck is ERC20, ERC20Burnable {
    constructor() ERC20("Fortune Luck", "FL") {
        _mint(msg.sender, 777777777 * 10 ** decimals());
    }
}
