// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./BasicWithdraw.sol";
import "./OwnerController.sol";

struct WithdrawSplit {
    /// @dev the recipient to recieve the funds
    address recipient;
    /// @dev bps is a 00 number, so 10% is 1000
    uint256 bps;
}

abstract contract WithdrawSplitter is BasicWithdraw {
    WithdrawSplit[] public withdrawSplits;

    constructor(WithdrawSplit[] memory _withdrawSplits) {
        _setWithdrawSplit(_withdrawSplits);
    }

    /// @dev set new withdraw splits
    function _setWithdrawSplit(WithdrawSplit[] memory _withdrawSplits)
        internal
    {
        delete withdrawSplits;
        uint256 length = _withdrawSplits.length;
        for (uint256 i = 0; i < length; i++) {
            withdrawSplits.push(_withdrawSplits[i]);
        }
    }

    /// @dev allows to withdraw funds from the contract, splitted
    function _splitWithdraw(uint256 amount) internal {
        uint256 length = withdrawSplits.length;
        for (uint256 i = 0; i < length; i++) {
            WithdrawSplit memory split = withdrawSplits[i];
            _withdraw(payable(split.recipient), (amount * split.bps) / 10000);
        }
    }
}
