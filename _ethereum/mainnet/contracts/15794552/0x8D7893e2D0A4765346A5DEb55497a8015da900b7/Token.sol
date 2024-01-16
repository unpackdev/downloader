// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor(address[] memory _minterAddresses) ERC20("Porkers", "PORK") {
        uint256 _minterAddressesLength = _minterAddresses.length;
        // Mint 36,665 tokens for each team address
        for (uint256 i = 0; i < _minterAddressesLength;) {
            _mint(_minterAddresses[i], 36665 * 10**uint(decimals()));
            unchecked { ++i; }
        }
    }
}