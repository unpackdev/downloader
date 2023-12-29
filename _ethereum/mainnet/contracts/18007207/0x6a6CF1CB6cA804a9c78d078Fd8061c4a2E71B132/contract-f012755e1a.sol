// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract HarryPotterTrumpObamaPepe is ERC20, Ownable {
    constructor() ERC20("HarryPotterTrumpObamaPepe", "QUANT") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}
