// contracts/VBToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract VBToken is ERC20, ERC20Burnable {
    constructor() ERC20("Vibranium", "VBX") {
        _mint(msg.sender, 1000000000000000000000000000);
    }
}
