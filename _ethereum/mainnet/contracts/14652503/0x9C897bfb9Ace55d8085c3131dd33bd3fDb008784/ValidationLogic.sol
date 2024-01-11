// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./DataTypes.sol";
import "./CreditSystem.sol";
import "./KyokoMath.sol";
import "./PercentageMath.sol";
import "./ReserveLogic.sol";
import "./GenericLogic.sol";
import "./SafeMathUpgradeable.sol";

/**
 * @title ReserveLogic library
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using SafeMathUpgradeable for uint256;
    using KyokoMath for uint256;
    using PercentageMath for uint256;

    uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 4000;
    uint256 public constant REBALANCE_UP_USAGE_RATIO_THRESHOLD = 0.95 * 1e27; //usage ratio of 95%

    /**
    * @dev Validates a deposit action
    * @param reserve The reserve object on which the user is depositing
    * @param amount The amount to be deposited
    */
    function validateDeposit(DataTypes.ReserveData storage reserve, uint256 amount) external view {
        bool isActive = reserve.getActive();
        require(amount != 0, "VL_INVALID_AMOUNT");
        require(isActive, "VL_NO_ACTIVE_RESERVE");
    }

    /**
    * @dev Validates a withdraw action
    * @param reserveAddress The address of the reserve
    * @param amount The amount to be withdrawn
    * @param userBalance The balance of the user
    * @param reservesData The reserves state
    */
    function validateWithdraw(
        address reserveAddress,
        uint256 amount,
        uint256 userBalance,
        mapping(address => DataTypes.ReserveData) storage reservesData
    ) external view {
        require(amount != 0, "VL_INVALID_AMOUNT");
        require(amount <= userBalance, "VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE");

        bool isActive = reservesData[reserveAddress].getActive();
        require(isActive, "VL_NO_ACTIVE_RESERVE");
    }

    struct ValidateBorrowLocalVars {
        uint256 userBorrowBalance;
        uint256 availableLiquidity;
        bool isActive;
    }

    /**
    * @dev Validates a borrow action
    * @param availableBorrowsInWEI available borrows in WEI
    * @param reserve The reserve state from which the user is borrowing
    * @param amount The amount to be borrowed
    */

    function validateBorrow(
        uint256 availableBorrowsInWEI,
        DataTypes.ReserveData storage reserve,
        uint256 amount
    ) external view {
        ValidateBorrowLocalVars memory vars;
        require(availableBorrowsInWEI > 0, "available credit line not enough");
        uint256 decimals_ = 1 ether;
        uint256 borrowsAmountInWEI = amount.div(10**reserve.decimals).mul(uint256(decimals_));
        require(borrowsAmountInWEI <= availableBorrowsInWEI, "borrows exceed credit line");
        
        vars.isActive = reserve.getActive();

        require(vars.isActive, "VL_NO_ACTIVE_RESERVE");
        require(amount > 0, "VL_INVALID_AMOUNT");
    }

    /**
    * @dev Validates a repay action
    * @param reserve The reserve state from which the user is repaying
    * @param amountSent The amount sent for the repayment. Can be an actual value or type(uint256).min
    * @param onBehalfOf The address of the user msg.sender is repaying for
    * @param variableDebt The borrow balance of the user
    */
    function validateRepay(
        DataTypes.ReserveData storage reserve,
        uint256 amountSent,
        address onBehalfOf,
        uint256 variableDebt
    ) external view {
        bool isActive = reserve.getActive();

        require(isActive, "VL_NO_ACTIVE_RESERVE");

        require(amountSent > 0, "VL_INVALID_AMOUNT");

        require(variableDebt > 0, "VL_NO_DEBT_OF_SELECTED_TYPE");

        require(
            amountSent != type(uint256).max || msg.sender == onBehalfOf,
            "VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF"
        );
    }
}