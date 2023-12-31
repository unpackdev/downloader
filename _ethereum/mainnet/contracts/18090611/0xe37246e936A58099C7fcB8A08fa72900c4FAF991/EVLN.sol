// SPDX-License-Identifier: MIT

//** Evelon ERC20 Token */
pragma solidity 0.8.18;

import "./ERC20Burnable.sol";

contract EVLN is ERC20Burnable {
    constructor() ERC20("Evelon Token", "EVLN") {
        _mint(msg.sender, 250_000_000 * 10 ** decimals());
    }
}