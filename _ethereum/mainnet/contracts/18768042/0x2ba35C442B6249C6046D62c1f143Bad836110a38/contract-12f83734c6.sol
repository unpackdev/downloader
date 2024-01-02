// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract Cryptonic is ERC20 {
    constructor() ERC20("Cryptonic", "CMT") {
        _mint(msg.sender, 333000000 * 10 ** decimals());
    }
}
