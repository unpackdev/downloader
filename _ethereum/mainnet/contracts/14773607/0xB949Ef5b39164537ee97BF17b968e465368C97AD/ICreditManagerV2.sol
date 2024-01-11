// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IPriceOracle.sol";
import "./IVersion.sol";
interface ICreditManagerV2Events {
    // Emit each time when financial order is executed
    event ExecuteOrder(address indexed borrower, address indexed target);
    event NewConfigurator(address indexed newConfigurator);
}

interface ICreditManagerV2Exceptions {
    error AdaptersOrFacadeOnlyException();

    error NotCreditFacadeException();

    error NotCreditConfiguratorException();

    error BorrowAmountOutOfLimitsException();

    error ZeroAddressOrUserAlreadyHasAccountException();

    error TargetContractNotAllowedExpcetion();

    error NotEnoughCollateralException();

    error TokenNotAllowedException();

    error HasNoOpenedAccountException();

    error TokenAlreadyAddedException();

    error TooMuchTokensException();

    error IncorrectLimitsException();
}

/// @title Credit Manager interface
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
interface ICreditManagerV2 is
    ICreditManagerV2Events,
    ICreditManagerV2Exceptions,
    IVersion
{
    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    /**
     * @dev Opens credit account and provides credit funds.
     * - Opens credit account (take it from account factory)
     * - Transfers trader /farmers initial funds to credit account
     * - Transfers borrowed leveraged amount from pool (= amount x leverageFactor) calling lendCreditAccount() on connected Pool contract.
     * - Emits OpenCreditAccount event
     * Function reverts if user has already opened position
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
     *
     * @param borrowedAmount Borrowers own funds
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     */
    function openCreditAccount(uint256 borrowedAmount, address onBehalfOf)
        external
        returns (address);

    function closeCreditAccount(
        address borrower,
        bool isLiquidated,
        uint256 totalValue,
        address caller,
        address to,
        uint256 skipTokenMask,
        bool convertWETH
    ) external returns (uint256 remainingFunds);

    /// @dev Increases borrowed amount by transferring additional funds from
    /// the pool if after that HealthFactor > minHealth
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#increase-borrowed-amount
    ///
    /// @param amount Amount to increase borrowed amount
    function manageDebt(
        address borrower,
        uint256 amount,
        bool increase
    ) external returns (uint256 newBorrowedAmount);

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address payer,
        address onBehalfOf,
        address token,
        uint256 amount
    ) external;

    function version() external view returns (uint256);

    /// @dev Executes filtered order on credit account which is connected with particular borrowers
    /// @param borrower Borrower address
    /// @param target Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address target,
        bytes memory data
    ) external returns (bytes memory);

    /// @dev Approve tokens for credit account. Restricted for adapters only
    /// @param borrower Address of borrower
    /// @param targetContract Contract to check allowance
    /// @param token Token address of contract
    /// @param amount Allowanc amount
    function approveCreditAccount(
        address borrower,
        address targetContract,
        address token,
        uint256 amount
    ) external;

    function transferAccountOwnership(address from, address to) external;

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    //    function feeSuccess() external view returns (uint256);

    function feeInterest() external view returns (uint256);

    function feeLiquidation() external view returns (uint256);

    function liquidationDiscount() external view returns (uint256);

    function creditFacade() external view returns (address);

    function priceOracle() external view returns (IPriceOracleV2);

    /// @dev Return enabled tokens - token masks where each bit is "1" is token is enabled
    function enabledTokensMap(address creditAccount)
        external
        view
        returns (uint256);

    function liquidationThresholds(address token)
        external
        view
        returns (uint256);

    /// @dev Returns of token address from allowed list by its id
    function allowedTokens(uint256 id) external view returns (address);

    /// @dev Checks that token is allowed to be used as collateral and enable it token mask. 
    /// Reverts if token not allowed to be used as collateral
    function checkAndEnableToken(address creditAccount, address tokenOut)
        external;

    function fastCollateralCheck(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 balanceInBefore,
        uint256 balanceOutBefore
    ) external;

    function fullCollateralCheck(address creditAccount) external;

    /// @dev Returns quantity of tokens in allowed list
    function allowedTokensCount() external view returns (uint256);

    /// @dev Returns debt and debt + interest for particular credit account
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (uint256 borrowedAmount, uint256 borrowedAmountWithInterest);

    // map token address to its mask
    function tokenMasksMap(address token) external view returns (uint256);

    // Mask for forbidden tokens
    function forbiddenTokenMask() external view returns (uint256);

    /// @return Contract address connected with provided adapter
    function adapterToContract(address adapter) external view returns (address);

    /// @return minimal borrowed amount per credit account
    function minBorrowedAmount() external view returns (uint256);

    /// @return maximum borrowed amount per credit account
    function maxBorrowedAmount() external view returns (uint256);

    /// @dev Returns underlying token address
    function underlying() external view returns (address);

    /// @dev Returns address of connected pool, please use pool instead
    function pool() external view returns (address);

    /// @dev [DEPRICIATED]: Returns address of connected pool, please use pool instead
    function poolService() external view returns (address);

    /// @dev Returns address of CreditFilter
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Returns address of connected pool
    function creditConfigurator() external view returns (address);

    /// @dev Returns address of weth address
    function wethAddress() external view returns (address);

    /// @dev Computes close / liquidation payments
    function calcClosePayments(
        uint256 totalValue,
        bool isLiquidated,
        uint256 borrowedAmount,
        uint256 borrowedAmountWithInterest
    )
        external
        view
        returns (
            uint256 amountToPool,
            uint256 remainingFunds,
            uint256 profit,
            uint256 loss
        );
}
