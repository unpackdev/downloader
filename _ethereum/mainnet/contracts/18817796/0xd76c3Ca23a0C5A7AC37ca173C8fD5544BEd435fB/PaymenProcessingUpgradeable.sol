// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./SafeTransfer.sol";

abstract contract PaymenProcessingUpgradeable {
    error Payment__InsufficientBalance();
    error Payment__InvalidPercentage();

    event ReferralBonus(address referrer, uint256 referralBonus);

    uint96 constant HUNDER_PERCENT_IN_BPS = 10_000;

    struct FeeInfo {
        address recipient;
        uint96 percentageInBps;
    }

    FeeInfo public clientInfo;
    FeeInfo public systemInfo;

    uint96 public affiliatePercentageInBps;

    function _processPayment(address paymentToken_, uint256 total_, uint256 net_, address payer_, address) internal {
        if (paymentToken_ == address(0)) {
            uint256 value = msg.value;
            if (value < total_) revert Payment__InsufficientBalance();

            SafeTransferLib.safeTransferETH(clientInfo.recipient, net_);
            SafeTransferLib.safeTransferETH(systemInfo.recipient, total_ - net_);
        } else {
            SafeTransferLib.safeTransferFrom(paymentToken_, payer_, clientInfo.recipient, net_);
            SafeTransferLib.safeTransferFrom(paymentToken_, payer_, systemInfo.recipient, total_ - net_);
        }
    }

    uint256[47] private __gap;
}
