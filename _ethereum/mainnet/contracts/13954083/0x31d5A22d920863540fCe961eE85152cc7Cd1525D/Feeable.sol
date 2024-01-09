// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Address.sol";

struct FeeableConfig {
    address payable treasuryWalletAddress;
    uint256 feeBps;
}

abstract contract Feeable {
    FeeableConfig public _feeableConfig;

    modifier feeableConfigSet() {
        require(
            _feeableConfig.treasuryWalletAddress != address(0),
            "Feeable: _feeableConfig not set"
        );
        _;
    }

    function deductFees(uint256 amount)
        internal
        feeableConfigSet
        returns (uint256)
    {
        uint256 feeAmount = (amount * _feeableConfig.feeBps) / 10000;
        Address.sendValue(_feeableConfig.treasuryWalletAddress, feeAmount);
        return amount - feeAmount;
    }
}
