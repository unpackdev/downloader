// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IPriceFeed.sol";
import "./ISimpleERCFund.sol";
import "./IOracle.sol";

interface IGovernance {
    function getDeploymentStartTime() external view returns (uint256);

    function getBorrowingFeeFloor() external view returns (uint256);

    function getRedemptionFeeFloor() external view returns (uint256);

    function getMaxBorrowingFee() external view returns (uint256);

    function getMaxDebtCeiling() external view returns (uint256);

    function getAllowMinting() external view returns (bool);

    function getPriceFeed() external view returns (IPriceFeed);

    function getStabilityFee() external view returns (uint256);

    function getStabilityFeeToken() external view returns (IERC20);

    function getStabilityTokenPairOracle() external view returns (IOracle);

    function getFund() external view returns (ISimpleERCFund);

    function chargeStabilityFee(address who, uint256 LUSDAmount) external;

    function sendToFund(address token, uint256 amount, string memory reason) external;
}
