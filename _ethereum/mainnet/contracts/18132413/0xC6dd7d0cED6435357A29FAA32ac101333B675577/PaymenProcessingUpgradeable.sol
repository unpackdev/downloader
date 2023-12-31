// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IERC20Upgradeable.sol";
import "./IPaymentProcessingUpgradeable.sol";
import "./BaseUpgradeable.sol";
import "./BusinessAddressesUpgradeable.sol";
import "./FeeDistributorUpgradeable.sol";
import "./BitMaps.sol";
import "./SafeTransfer.sol";
import "./Helper.sol";
import "./Constants.sol";

abstract contract PaymenProcessingUpgradeable is
    IPaymentProcessingUpgradeable,
    BaseUpgradeable,
    BusinessAddressesUpgradeable,
    FeeDistributorUpgradeable
{
    address public systemAddress;
    uint96 public minimumThresholdInBps;
    uint96 public affiliatePercentageInBps;

    function configThreshold(uint96 slippagePercentInBps_) external onlyRole(OPERATOR_ROLE) {
        minimumThresholdInBps = HUNDER_PERCENT_IN_BPS - slippagePercentInBps_;
    }

    function configAffiliatePercentage(uint96 affiliatePercentageInBps_) external onlyRole(OPERATOR_ROLE) {
        affiliatePercentageInBps = affiliatePercentageInBps_;
    }

    function configSystemAddress(address systemAddress_) external onlyRole(OPERATOR_ROLE) {
        systemAddress = systemAddress_;
    }

    function _calculateAmounts(
        uint256 value_,
        uint256 discountTotal_,
        uint256 total_,
        address affiliate_
    ) internal view returns (uint256 primarySaleAmount, uint256 affiliateAmount, uint256 systemAmount) {
        if (value_ < discountTotal_) revert Payment__InsufficientBalance();

        uint256 clientPercentage = _clientInfo.percentageInBps;
        uint256 affiliatePercentage = affiliatePercentageInBps;

        if (affiliate_ == address(0)) {
            primarySaleAmount = (total_ * (clientPercentage + affiliatePercentage)) / HUNDER_PERCENT_IN_BPS;
            affiliateAmount = 0;
        } else {
            primarySaleAmount = (total_ * clientPercentage) / HUNDER_PERCENT_IN_BPS;
            affiliateAmount = (total_ * affiliatePercentage) / HUNDER_PERCENT_IN_BPS;
        }

        if (systemAddress != address(0)) {
            systemAmount = value_ - primarySaleAmount - affiliateAmount;
        } else {
            primarySaleAmount = value_ - affiliateAmount;
        }
    }

    function _processPayment(
        address paymentToken_,
        uint256 total_,
        address payer_,
        address affiliate_
    ) internal returns (uint256 primarySaleAmount, uint256 affiliateAmount, uint256 systemAmount) {
        uint256 discountTotal = total_;
        uint256 value;

        if (isBusiness(payer_)) discountTotal = (total_ * minimumThresholdInBps) / HUNDER_PERCENT_IN_BPS;

        if (paymentToken_ == address(0)) {
            value = msg.value;
            (primarySaleAmount, affiliateAmount, systemAmount) = _calculateAmounts(
                value,
                discountTotal,
                total_,
                affiliate_
            );
            SafeTransferLib.safeTransferETH(_clientInfo.recipient, primarySaleAmount);
            SafeTransferLib.safeTransferETH(affiliate_, affiliateAmount);
            SafeTransferLib.safeTransferETH(systemAddress, systemAmount);
        } else {
            value = IERC20Upgradeable(paymentToken_).allowance(payer_, address(this));
            (primarySaleAmount, affiliateAmount, systemAmount) = _calculateAmounts(
                value,
                discountTotal,
                total_,
                affiliate_
            );

            SafeTransferLib.safeTransferFrom(paymentToken_, payer_, _clientInfo.recipient, primarySaleAmount);
            SafeTransferLib.safeTransferFrom(paymentToken_, payer_, affiliate_, affiliateAmount);
            SafeTransferLib.safeTransferFrom(paymentToken_, payer_, systemAddress, systemAmount);
        }
    }

    uint256[48] private __gap;
}
