// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract PENNY is ERC20 {
    constructor() ERC20("PENNY", "PENNY") {
        _mint(msg.sender, 130000000000 * 10 ** decimals());
    }
}