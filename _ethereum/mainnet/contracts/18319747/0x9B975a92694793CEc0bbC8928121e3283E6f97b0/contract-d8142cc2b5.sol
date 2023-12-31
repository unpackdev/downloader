// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract RichSimba is ERC20, ERC20Burnable {
    constructor() ERC20("RichSimba", "SIMBA") {
        _mint(msg.sender, 5000000000 * 10 ** decimals());
    }
}
