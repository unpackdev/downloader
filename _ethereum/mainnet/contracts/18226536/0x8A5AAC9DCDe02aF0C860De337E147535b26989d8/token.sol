// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract G25gle is ERC20, Ownable {
    constructor() ERC20("G25gle", "G25gle") {
        _mint(msg.sender, 2500000000000 * 10 ** decimals());
    }
}