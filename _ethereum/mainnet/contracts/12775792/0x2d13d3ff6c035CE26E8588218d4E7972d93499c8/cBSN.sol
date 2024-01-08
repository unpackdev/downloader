pragma solidity 0.7.6;

// SPDX-License-Identifier: MIT

import "./ERC20.sol";

contract cBSN is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _initialSupplyRecipient
    ) ERC20(_name, _symbol) {
        uint256 initialSupply = 500_000_000 * 10 ** 18;
        _mint(_initialSupplyRecipient, initialSupply);
    }
}
