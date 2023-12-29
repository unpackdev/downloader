// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.21;

import "./IPartyVaultRouterEvents.sol";
import "./IPartyVaultRouterErrors.sol";

/**
 * @title IPartyVaultRouter
 * @notice Interface for the PartyVaultRouter contract
 */
interface IPartyVaultRouter is IPartyVaultRouterEvents, IPartyVaultRouterErrors {
    /**
     * @notice Enum used to determine which interface should be used when interacting with a reward program
     */
    enum RewardProgram {
        Points,
        Geyser
    }

    /**
     * @notice Encodes a request to add a lock to a vault
     * @param rewardProgramType Used to determine what interface to use when interacting with the reward program
     * @param rewardProgram The address of the reward program
     * @param amount The amount of tokens to lock against this reward program
     * @param permission The owner's permission to add the lock to the vault
     */
    struct LockRequest {
        RewardProgram rewardProgramType;
        address rewardProgram;
        uint128 amount;
        bytes permission;
    }

    /**
     * @notice Encodes a request to remove a lock from a vault
     * @param rewardProgramType Used to determine what interface to use when interacting with the reward program
     * @param rewardProgram The address of the reward program
     * @param amount The amount of tokens to unlock from this reward program
     * @param permission The owner's permission to remove the lock from the vault
     */
    struct UnlockRequest {
        RewardProgram rewardProgramType;
        address rewardProgram;
        uint128 amount;
        bytes permission;
    }

    /**
     * @notice Create a new vault for a user, deposit tokens, and lock
     * @param vaultFactory The address of the vault factory to use
     * @param salt The salt to use for the vault creation
     * @param token The address of the token to deposit
     * @param amount The amount of tokens to deposit
     * @param requests Set of requests to lock the deposited tokens against different reward programs
     * @return vault The address of the newly created vault
     */
    function createAndDeposit(
        address vaultFactory,
        bytes32 salt,
        address token,
        uint128 amount,
        LockRequest[] calldata requests
    ) external returns (address vault);

    /**
     * @notice Deposit tokens into a pre-existing vault and lock
     * @param vault The address of the vault to deposit into
     * @param token The address of the token to deposit
     * @param amount The amount of tokens to deposit
     * @param requests Set of requests to lock the deposited tokens against different reward programs
     */
    function deposit(address vault, address token, uint128 amount, LockRequest[] calldata requests) external;

    /**
     * @notice Unlocks tokens from a set of reward programs
     * @dev Due to the current vault implementation, token withdrawal cannot be bundled into this operation.
     * @param vault The address of the vault to unlock
     * @param token The address of the token to unlock
     * @param requests Set of requests to unlock the deposited tokens from different reward programs
     */
    function unlock(address vault, address token, UnlockRequest[] calldata requests) external;
}
