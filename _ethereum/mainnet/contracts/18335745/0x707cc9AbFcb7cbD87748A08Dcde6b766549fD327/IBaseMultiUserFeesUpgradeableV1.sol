// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface IBaseMultiUserFeesUpgradeableV1 {
    event FeeAccountUpdated(address actor, address feeAccount);

    event RedemptionFee(address actor, address asset, uint256 amount, uint256 feeAmount, uint256 additionalFeeAmount);

    event RedemptionFeeUpdated(address actor, uint256 redemptionFee);

    function getFeesAccount() external view returns (address);

    function getRedemptionFeeAmount(uint256 amount) external view returns (uint256 feeAmount);

    function getRedemptionFee() external view returns (uint256 percent4);

    function setFeesAccount(address) external;

    function setRedemptionFee(uint256) external;
}
