// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract NeverSurrender is ERC20, Ownable {
    constructor() ERC20("Never Surrender!", "NEVER") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}
