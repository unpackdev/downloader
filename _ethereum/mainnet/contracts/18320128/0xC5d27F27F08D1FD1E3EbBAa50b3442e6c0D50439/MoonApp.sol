// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract MoonApp is ERC20, ERC20Burnable, ERC20Permit {
    uint256 public constant TOTAL_SUPPLY = 3_000_000_000 ether;

    constructor() ERC20("Moon App", "APP") ERC20Permit("Moon App") {
        _mint(0xb64e395cbFCdc46c993ed9F181e0161E4AA8798a, TOTAL_SUPPLY);
    }
}
