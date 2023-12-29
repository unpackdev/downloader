// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TheFinal20 is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("The Final 2.0", "FINAL") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
