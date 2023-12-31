// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Lena is ERC20 {
    constructor() ERC20("Lena", "Lena") {
        _mint(0x233a6A22C16325fE013aD0d03A525CD6472b9d08, 100_000_000e18);
    }
}
