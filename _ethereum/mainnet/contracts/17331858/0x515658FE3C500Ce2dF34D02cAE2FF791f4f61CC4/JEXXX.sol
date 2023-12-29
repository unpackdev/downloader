// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract JessicaRabbit is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Jessica Rabbit", "JEXXX") {
        _mint(msg.sender, 696969696969 * 10 ** decimals());
    }
}