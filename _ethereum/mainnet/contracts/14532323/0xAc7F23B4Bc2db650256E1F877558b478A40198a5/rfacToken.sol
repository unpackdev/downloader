// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";

contract rfacToken is ERC20 {
    constructor() ERC20("RFAC CHIP", "CHIP") {
        _mint(msg.sender, 10000000000 * 10**uint(18));
    }
}