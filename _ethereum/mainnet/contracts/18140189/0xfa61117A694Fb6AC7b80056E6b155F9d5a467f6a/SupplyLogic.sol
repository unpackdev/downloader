// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IMToken.sol";

import "./Errors.sol";
import "./DataTypes.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./ReserveLogic.sol";
import "./ValidationLogic.sol";

/**
 * @title SupplyLogic library
 * @author MetaFire
 * @notice Implements the logic to supply feature
 */
library SupplyLogic {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveLogic for DataTypes.ReserveData;

  /**
   * @dev Emitted on deposit()
   * @param user The address initiating the deposit
   * @param amount The amount deposited
   * @param reserve The address of the underlying asset of the reserve
   * @param onBehalfOf The beneficiary of the deposit, receiving the mTokens
   * @param referral The referral code used
   **/
  event Deposit(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed onBehalfOf,
    uint8 period,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param user The address initiating the withdrawal, owner of mTokens
   * @param reserve The address of the underlyng asset being withdrawn
   * @param amount The amount to be withdrawn
   * @param to Address that will receive the underlying
   **/
  event Withdraw(address indexed user, address indexed reserve, uint256 amount, address indexed to, uint8 period);

  /**
   * @notice Implements the supply feature. Through `deposit()`, users deposit assets to the protocol.
   * @dev Emits the `Deposit()` event.
   * @param reservesData The state of all the reserves
   * @param params The additional parameters needed to execute the deposit function
   */
  function executeDeposit(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ExecuteDepositParams memory params
  ) external {
    require(params.onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);
    uint8 period = uint8(params.period);
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    address mToken = reserve.mTokenAddresses[period];
    require(mToken != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    ValidationLogic.validateDeposit(reserve, params.amount);

    reserve.updateState();
    reserve.updateInterestRates(params.asset, mToken, params.amount, 0);

    IERC20Upgradeable(params.asset).safeTransferFrom(params.initiator, address(this), params.amount);

    IMToken(mToken).mint(params.onBehalfOf, params.amount, reserve.liquidityIndices[period]);

    emit Deposit(params.initiator, params.asset, params.amount, params.onBehalfOf,uint8(params.period) ,params.referralCode);
  }

  /**
   * @notice Implements the supply feature. Through `withdraw()`, users withdraw assets from the protocol.
   * @dev Emits the `Withdraw()` event.
   * @param reservesData The state of all the reserves
   * @param params The additional parameters needed to execute the withdraw function
   */
  function executeWithdraw(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    DataTypes.ExecuteWithdrawParams memory params
  ) external returns (uint256) {
    require(params.to != address(0), Errors.VL_INVALID_TARGET_ADDRESS);
    uint8 period = uint8(params.period);
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    address mToken = reserve.mTokenAddresses[period];
    require(mToken != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    uint256 userBalance = IMToken(mToken).balanceOf(params.initiator);

    uint256 amountToWithdraw = params.amount;

    if (params.amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    ValidationLogic.validateWithdraw(reserve, amountToWithdraw, userBalance);

    reserve.updateState();

    reserve.updateInterestRates(params.asset, mToken, 0, amountToWithdraw);

    IMToken(mToken).burn(params.initiator, params.to, amountToWithdraw, reserve.liquidityIndices[period]);

    IERC20Upgradeable(params.asset).safeTransfer(params.to, amountToWithdraw);

    emit Withdraw(params.initiator, params.asset, amountToWithdraw, params.to, period);

    return amountToWithdraw;
  }
}
