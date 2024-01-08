// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract MuskCoin is ERC20 {
    address internal PRISM_TREASURY = 0x5ABBd94bb0561938130d83FdA22E672110e12528;

    constructor() ERC20("MuskCoin", "MUSK") {
        _mint(PRISM_TREASURY, 100000 * 1e18);
    }
}