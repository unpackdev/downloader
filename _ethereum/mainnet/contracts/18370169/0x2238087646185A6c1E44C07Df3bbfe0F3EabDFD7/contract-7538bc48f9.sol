// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Splito is ERC20, ERC20Burnable {
    constructor() ERC20("Splito", "SPL") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
