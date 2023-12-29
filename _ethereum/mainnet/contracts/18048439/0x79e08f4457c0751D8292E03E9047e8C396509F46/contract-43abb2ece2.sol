// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract RECESSION is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("RECESSION", "RECESS") {
        _mint(msg.sender, 13000000 * 10 ** decimals());
    }
}
