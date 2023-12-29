// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract HarryPotterTrumpStonks is ERC20, Ownable {
    constructor() ERC20("HarryPotterTrumpStonks", "SHREK") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
