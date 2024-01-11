// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @notice
 *
 */
interface IFeeupgradeable {
    function getFee() external view returns (uint256);

    function getFeeCollector() external view returns (address);

    function geThresholdMinimumFee() external view returns (uint256);

    function determineFee(
        uint256 withdrawn,
        uint256 sharesToInvestedTokens,
        address receiver,
        uint256 _fee
    ) external view returns (uint256 deductedTokenFees);

    function validateFee(uint256 feePercentage)
        external
        view
        returns (bool isValidFee);
}
