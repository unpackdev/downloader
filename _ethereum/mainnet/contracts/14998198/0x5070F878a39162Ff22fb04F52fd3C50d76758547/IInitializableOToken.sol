// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "./IRewardController.sol";
import "./IPool.sol";

/**
 * @title IInitializableOToken
 *
 * @notice Interface for the initialize function on OToken
 **/
interface IInitializableOToken {
    /**
     * @dev Emitted when an oToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param treasury The address of the treasury
     * @param incentivesController The address of the incentives controller for this oToken
     * @param oTokenDecimals The decimals of the underlying
     * @param oTokenName The name of the oToken
     * @param oTokenSymbol The symbol of the oToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        address incentivesController,
        uint8 oTokenDecimals,
        string oTokenName,
        string oTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the oToken
     * @param pool The pool contract that is initializing this contract
     * @param treasury The address of the Omni treasury, receiving the fees on this oToken
     * @param underlyingAsset The address of the underlying asset of this oToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param oTokenDecimals The decimals of the oToken, same as the underlying asset's
     * @param oTokenName The name of the oToken
     * @param oTokenSymbol The symbol of the oToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address treasury,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 oTokenDecimals,
        string calldata oTokenName,
        string calldata oTokenSymbol,
        bytes calldata params
    ) external;
}
