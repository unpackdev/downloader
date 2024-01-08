// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IFinder.sol";
import "./FixedPoint.sol";
import "./FeePayerParty.sol";

/**
 * @title Interface for interacting with the Derivatives contracts
 */
interface IDerivativeMain {
  /** @notice Deposit funds to a certain derivative contract with specified sponsor
   * @param sponsor Address of the sponsor to which the funds will be deposited
   * @param collateralAmount Amount of funds to be deposited
   */
  function depositTo(
    address sponsor,
    FixedPoint.Unsigned memory collateralAmount
  ) external;

  /** @notice Deposit funds to the derivative contract where msg sender is the sponsor
   * @param collateralAmount Amount of funds to be deposited
   */
  function deposit(FixedPoint.Unsigned memory collateralAmount) external;

  /** @notice Fast withdraw excess collateral from a derivative contract
   * @param collateralAmount Amount of funds to be withdrawn
   */
  function withdraw(FixedPoint.Unsigned memory collateralAmount)
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  /** @notice Request of slow withdraw of collateral from derivative changing GCR
   * @param collateralAmount Amount of funds to be withdrawn
   */
  function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
    external;

  /** @notice Execute withdraw if a slow withdraw request has passed
   */
  function withdrawPassedRequest()
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  /** @notice Cancel a slow withdraw request
   */
  function cancelWithdrawal() external;

  /** @notice Mint synthetic tokens
   * @param collateralAmount Amount of collateral to be locked
   * @param numTokens Amount of tokens to be minted based on collateralAmount
   */
  function create(
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external;

  /** @notice Redeem collateral by burning synthetic tokens
   * @param numTokens Amount of synthetic tokens to be burned to unlock collateral
   */
  function redeem(FixedPoint.Unsigned memory numTokens)
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  /** @notice Burning an amount of synthetic tokens to increase GCR
   * @param numTokens Amount of synthetic tokens to be burned
   */
  function repay(FixedPoint.Unsigned memory numTokens) external;

  /** @notice Settles the withdraws from an emergency shutdown of a derivative
   */
  function settleEmergencyShutdown()
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  /** @notice Invokes an emergency shutdown of a derivative
   */
  function emergencyShutdown() external;

  /** @notice Remargin function
   */
  function remargin() external;

  /** @notice Allows withdrawing of excess ERC20 tokens
   * @param token The address of the ERC20 token
   */
  function trimExcess(IERC20 token)
    external
    returns (FixedPoint.Unsigned memory amount);

  /** @notice Gets the collateral locked by a certain sponsor
   * @param sponsor The address of the sponsor for which to return amount of collateral locked
   */
  function getCollateral(address sponsor)
    external
    view
    returns (FixedPoint.Unsigned memory collateralAmount);

  /** @notice Gets the address of the SynthereumFinder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /** @notice Gets the synthetic token symbol associated with the derivative
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);

  /** @notice Gets the price identifier associated with the derivative
   */
  function priceIdentifier() external view returns (bytes32 identifier);

  /** @notice Gets the total collateral locked in a derivative
   */
  function totalPositionCollateral()
    external
    view
    returns (FixedPoint.Unsigned memory totalCollateral);

  /** @notice Gets the total synthetic tokens minted through a derivative
   */
  function totalTokensOutstanding()
    external
    view
    returns (FixedPoint.Unsigned memory totalTokens);

  /** @notice Gets the price at which the emergency shutdown was performed
   */
  function emergencyShutdownPrice()
    external
    view
    returns (FixedPoint.Unsigned memory emergencyPrice);
}
