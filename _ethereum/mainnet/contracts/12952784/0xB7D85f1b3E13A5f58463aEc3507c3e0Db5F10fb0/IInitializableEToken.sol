// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./ILendingPool.sol";
import "./IEaveIncentivesController.sol";

/**
 * @title IInitializableEToken
 * @notice Interface for the initialize function on EvolutionToken
 * @author Evolution
 **/
interface IInitializableEToken {
  /**
   * @dev Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param eTokenDecimals the decimals of the underlying
   * @param eTokenName the name of the aToken
   * @param eTokenSymbol the symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 eTokenDecimals,
    string eTokenName,
    string eTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the aToken
   * @param pool The address of the lending pool where this aToken will be used
   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param eTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param eTokenName The name of the aToken
   * @param eTokenSymbol The symbol of the aToken
   */
  function initialize(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    IEaveIncentivesController incentivesController,
    uint8 eTokenDecimals,
    string calldata eTokenName,
    string calldata eTokenSymbol,
    bytes calldata params
  ) external;
}
