// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ERC20.sol";

contract XanaToken is ERC20 {
    constructor() ERC20("XanaToken", "Xana") public {
        _mint(msg.sender, 10000000 * 10 ** 18);
    }
}