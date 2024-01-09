// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Museion is ERC20, ERC20Burnable {
    constructor() ERC20("Museion", "MUSA") {
        ERC20._mint(msg.sender, 210000000 * 10 ** decimals());
    }
}
