// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./ILendingPool.sol";
import "./IUmeeIncentivesController.sol";

/**
 * @title IInitializableUToken
 * @notice Interface for the initialize function on UToken
 * @author Umee
 **/
interface IInitializableUToken {
  /**
   * @dev Emitted when an uToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this uToken
   * @param uTokenDecimals the decimals of the underlying
   * @param uTokenName the name of the uToken
   * @param uTokenSymbol the symbol of the uToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 uTokenDecimals,
    string uTokenName,
    string uTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the uToken
   * @param pool The address of the lending pool where this uToken will be used
   * @param treasury The address of the Umee treasury, receiving the fees on this uToken
   * @param underlyingAsset The address of the underlying asset of this uToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param uTokenDecimals The decimals of the uToken, same as the underlying asset's
   * @param uTokenName The name of the uToken
   * @param uTokenSymbol The symbol of the uToken
   */
  function initialize(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    IUmeeIncentivesController incentivesController,
    uint8 uTokenDecimals,
    string calldata uTokenName,
    string calldata uTokenSymbol,
    bytes calldata params
  ) external;
}
