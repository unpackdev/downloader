// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract HungPony is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Hung Pony", "HUNG") {
        _mint(msg.sender, 7844782268 * 10 ** decimals());
    }
}