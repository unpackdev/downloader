// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "./draft-ERC20Permit.sol";

contract TestERC20 is ERC20Permit {
    uint8 internal immutable decimals_;

    constructor(uint8 _decimals, uint _totalSupply) ERC20("Test", "TEST") ERC20Permit("Test") {
        _mint(msg.sender, _totalSupply);

        decimals_ = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return decimals_;
    }
}
