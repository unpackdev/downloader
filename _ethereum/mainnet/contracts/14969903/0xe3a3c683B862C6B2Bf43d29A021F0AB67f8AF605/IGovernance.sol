// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IPriceFeed.sol";
import "./IERC20.sol";
import "./IOracle.sol";

interface IGovernance {
    event AllowMintingChanged(bool oldFlag, bool newFlag, uint256 timestamp);
    event StabilityFeeChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event PriceFeedChanged(address oldAddress, address newAddress, uint256 timestamp);
    event MaxDebtCeilingChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event StabilityFeeTokenChanged(address oldAddress, address newAddress, uint256 timestamp);
    event StabilityTokenPairOracleChanged(address oldAddress, address newAddress, uint256 timestamp);
    event StabilityFeeCharged(uint256 LUSDAmount, uint256 feeAmount, uint256 timestamp);
    event FundAddressChanged(address oldAddress, address newAddress, uint256 timestamp);
    event SentToFund(address token, uint256 amount, uint256 timestamp, string reason);
    event RedemptionFeeFloorChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event BorrowingFeeFloorChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);
    event MaxBorrowingFeeChanged(uint256 oldValue, uint256 newValue, uint256 timestamp);

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

    function getFund() external view returns (address);

    function chargeStabilityFee(address who, uint256 LUSDAmount) external;
}
