// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract PND is ERC20 {
    constructor() ERC20("pnd DAO Token", "PND") {
        _mint(address(0x153d9DD730083e53615610A0d2f6F95Ab5A0Bc01), 1000000000 * 10 ** decimals());
    }
}
