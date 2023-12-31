// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract MCG is ERC20 {
    constructor() ERC20("MCG", "MCG") {
        _mint(0x4CbBb0a7b8a1a56ddf2727C52950CF80231E9cBD, 100_000_000e18);
    }
}
