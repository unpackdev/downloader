// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./ProtocolTypes.sol";
import "./ILendingMarketController.sol";

interface ITokenVault {
    error UnregisteredCurrency();
    error InvalidCurrency();
    error InvalidToken();
    error InvalidAmount(bytes32 ccy, uint256 amount, uint256 msgValue);
    error AmountIsZero();
    error CallerNotBaseCurrency(address caller);
    error MarketTerminated();
    error RedemptionIsRequired();

    event Deposit(address indexed user, bytes32 ccy, uint256 amount);
    event Withdraw(address indexed user, bytes32 ccy, uint256 amount);
    event Transfer(bytes32 indexed ccy, address indexed from, address indexed to, uint256 amount);
    event CurrencyRegistered(bytes32 ccy, address tokenAddress, bool isCollateral);
    event CurrencyUpdated(bytes32 ccy, bool isCollateral);

    function isCovered(address user) external view returns (bool);

    function isCollateral(bytes32 ccy) external view returns (bool);

    function isCollateral(bytes32[] calldata ccys) external view returns (bool[] memory);

    function isRegisteredCurrency(bytes32 ccy) external view returns (bool);

    function getTokenAddress(bytes32 ccy) external view returns (address);

    function getCollateralCurrencies() external view returns (bytes32[] memory);

    function getWithdrawableCollateral(address user) external view returns (uint256);

    function getWithdrawableCollateral(bytes32 ccy, address user) external view returns (uint256);

    function getCoverage(address user) external view returns (uint256);

    function getTotalUnusedCollateralAmount(address user) external view returns (uint256);

    function getTotalCollateralAmount(address user) external view returns (uint256);

    function getCollateralAmount(address user, bytes32 ccy) external view returns (uint256);

    function getBorrowableAmount(address user, bytes32 ccy) external view returns (uint256);

    function getLiquidationAmount(
        address user,
        bytes32 liquidationCcy,
        uint256 liquidationAmountMaximum
    ) external view returns (uint256 liquidationAmount, uint256 protocolFee, uint256 liquidatorFee);

    function getTotalDepositAmount(bytes32 ccy) external view returns (uint256);

    function getDepositAmount(address user, bytes32 ccy) external view returns (uint256);

    function getUsedCurrencies(address user) external view returns (bytes32[] memory);

    function calculateCoverage(
        address user,
        ILendingMarketController.AdditionalFunds memory funds
    ) external view returns (uint256 coverage, bool isInsufficientDepositAmount);

    function calculateLiquidationFees(
        uint256 liquidationAmount
    ) external view returns (uint256 protocolFee, uint256 liquidatorFee);

    function registerCurrency(bytes32 ccy, address tokenAddress, bool isCollateral) external;

    function updateCurrency(bytes32 ccy, bool isCollateral) external;

    function deposit(bytes32 ccy, uint256 amount) external payable;

    function depositFrom(address user, bytes32 ccy, uint256 amount) external payable;

    function withdraw(bytes32 ccy, uint256 amount) external;

    function addDepositAmount(address user, bytes32 ccy, uint256 amount) external;

    function removeDepositAmount(address user, bytes32 ccy, uint256 amount) external;

    function executeForcedReset(address user, bytes32 ccy) external returns (uint256 removedAmount);

    function transferFrom(
        bytes32 ccy,
        address sender,
        address receiver,
        uint256 amount
    ) external returns (uint256 untransferredAmount);

    function pause() external;

    function unpause() external;
}
