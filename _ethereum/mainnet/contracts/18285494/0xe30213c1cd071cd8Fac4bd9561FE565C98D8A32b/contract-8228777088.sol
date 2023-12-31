// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Pepe is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Pepe", "PEPE") {
        _mint(msg.sender, 420690000000000000 * 10 ** decimals());
    }
}
