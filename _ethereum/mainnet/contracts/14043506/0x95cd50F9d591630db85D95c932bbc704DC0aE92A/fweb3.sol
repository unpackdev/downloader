// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Fweb3 is ERC20, ERC20Burnable {
    constructor() ERC20("Fweb3", "FWEB3") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}
