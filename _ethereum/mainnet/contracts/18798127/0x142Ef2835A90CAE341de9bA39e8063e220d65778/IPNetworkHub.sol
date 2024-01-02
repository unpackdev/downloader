// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IGovernanceMessageHandler.sol";

/**
 * @title IPNetworkHub
 * @author pNetwork
 *
 * @notice
 */
interface IPNetworkHub is IGovernanceMessageHandler {
    enum ActorStatus {
        Active,
        Challenged,
        Inactive
    }

    enum ActorTypes {
        Governance,
        Guardian,
        Sentinel
    }

    enum ChallengeStatus {
        Null,
        Pending,
        Solved,
        Unsolved,
        PartiallyUnsolved,
        Cancelled
    }

    enum OperationStatus {
        NotQueued,
        Queued,
        Executed,
        Cancelled
    }

    struct Action {
        address actor;
        uint64 timestamp;
    }

    struct Challenge {
        uint256 nonce;
        address actor;
        address challenger;
        ActorTypes actorType;
        uint64 timestamp;
        bytes4 networkId;
    }

    struct Operation {
        bytes32 originBlockHash;
        bytes32 originTransactionHash;
        bytes32 optionsMask;
        uint256 nonce;
        uint256 underlyingAssetDecimals;
        uint256 assetAmount;
        uint256 userDataProtocolFeeAssetAmount;
        uint256 networkFeeAssetAmount;
        uint256 forwardNetworkFeeAssetAmount;
        address underlyingAssetTokenAddress;
        bytes4 originNetworkId;
        bytes4 destinationNetworkId;
        bytes4 forwardDestinationNetworkId;
        bytes4 underlyingAssetNetworkId;
        string originAccount;
        string destinationAccount;
        string underlyingAssetName;
        string underlyingAssetSymbol;
        bytes userData;
        bool isForProtocol;
    }

    /**
     * @dev Emitted when an actor is resumed after having being slashed
     *
     * @param epoch The epoch in which the actor has been resumed
     * @param actor The resumed actor
     */
    event ActorResumed(uint16 indexed epoch, address indexed actor);

    /**
     * @dev Emitted when an actor has been slashed on the interim chain.
     *
     * @param epoch The epoch in which the actor has been slashed
     * @param actor The slashed actor
     */
    event ActorSlashed(uint16 indexed epoch, address indexed actor);

    /**
     * @dev Emitted when a challenge is cancelled.
     *
     * @param challenge The challenge
     */
    event ChallengeCancelled(Challenge challenge);

    /**
     * @dev Emitted when a challenger claims the lockedAmountStartChallenge by providing a challenge.
     *
     * @param challenge The challenge
     */
    event ChallengePartiallyUnsolved(Challenge challenge);

    /**
     * @dev Emitted when a challenge is started.
     *
     * @param challenge The challenge
     */
    event ChallengePending(Challenge challenge);

    /**
     * @dev Emitted when a challenge is solved.
     *
     * @param challenge The challenge
     */
    event ChallengeSolved(Challenge challenge);

    /**
     * @dev Emitted when a challenge is used to slash an actor.
     *
     * @param challenge The challenge
     */
    event ChallengeUnsolved(Challenge challenge);

    /**
     * @dev Emitted when an operation is cancelled.
     *
     * @param operation The cancelled operation
     */
    event OperationCancelFinalized(Operation operation);

    /**
     * @dev Emitted when an actor instructs a cancel operation.
     *
     * @param operation The cancelled operation
     * @param actor the actor
     * @param actorType the actor type
     */
    event OperationCancelled(Operation operation, address indexed actor, ActorTypes indexed actorType);

    /**
     * @dev Emitted when an operation is executed.
     *
     * @param operation The executed operation
     */
    event OperationExecuted(Operation operation);

    /**
     * @dev Emitted when an operation is queued.
     *
     * @param operation The queued operation
     */
    event OperationQueued(Operation operation);

    /**
     * @dev Emitted when an user operation is generated.
     *
     * @param nonce The nonce
     * @param originAccount The account that triggered the user operation
     * @param destinationAccount The account to which the funds will be delivered
     * @param destinationNetworkId The destination network id
     * @param underlyingAssetName The name of the underlying asset
     * @param underlyingAssetSymbol The symbol of the underlying asset
     * @param underlyingAssetDecimals The number of decimals of the underlying asset
     * @param underlyingAssetTokenAddress The address of the underlying asset
     * @param underlyingAssetNetworkId The network id of the underlying asset
     * @param assetTokenAddress The asset token address
     * @param assetAmount The asset mount
     * @param userDataProtocolFeeAssetAmount the protocol fee asset amount for the user data
     * @param networkFeeAssetAmount the network fee asset amount
     * @param forwardNetworkFeeAssetAmount the forward network fee asset amount
     * @param forwardDestinationNetworkId the forward destination network id
     * @param userData The user data
     * @param optionsMask The options
     */
    event UserOperation(
        uint256 nonce,
        string originAccount,
        string destinationAccount,
        bytes4 destinationNetworkId,
        string underlyingAssetName,
        string underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId,
        address assetTokenAddress,
        uint256 assetAmount,
        uint256 userDataProtocolFeeAssetAmount,
        uint256 networkFeeAssetAmount,
        uint256 forwardNetworkFeeAssetAmount,
        bytes4 forwardDestinationNetworkId,
        bytes4 originNetworkId,
        bytes userData,
        bytes32 optionsMask,
        bool isForProtocol
    );

    /*
     * @notice Calculates the challenge id.
     *
     * @param challenge
     *
     * @return bytes32 representing the challenge id.
     */
    function challengeIdOf(Challenge memory challenge) external view returns (bytes32);

    /*
     * @notice Calculates the operation challenge period.
     *
     * @param operation
     *
     * @return (uint64, uin64) representing the start and end timestamp of an operation challenge period.
     */
    function challengePeriodOf(Operation calldata operation) external view returns (uint64, uint64);

    /*
     * @notice Offer the possibilty to claim the lockedAmountStartChallenge for a given challenge in a previous epoch in case it happens the following scenario:
     *          - A challenger initiates a challenge against a guardian/sentinel close to an epoch's end (within permissible limits).
     *          - The maxChallengeDuration elapses, disabling the sentinel from resolving the challenge within the currentEpoch.
     *          - The challenger fails to invoke slashByChallenge before the epoch terminates.
     *          - A new epoch initiates.
     *          - Result: lockedAmountStartChallenge STUCK.
     *
     * @param challenge
     *
     */
    function claimLockedAmountStartChallenge(Challenge calldata challenge) external;

    /*
     * @notice Return the epoch in which a challenge was started.
     *
     * @param challenge
     *
     * @return uint16 representing the epoch in which a challenge was started.
     */
    function getChallengeEpoch(Challenge calldata challenge) external view returns (uint16);

    /*
     * @notice Return the status of a challenge.
     *
     * @param challenge
     *
     * @return (ChallengeStatus) representing the challenge status
     */
    function getChallengeStatus(Challenge calldata challenge) external view returns (ChallengeStatus);

    /*
     * @notice Calculates the current active actors duration which is use to secure the system when few there are few active actors.
     *
     * @return uint64 representing the current active actors duration.
     */
    //function getCurrentActiveActorsAdjustmentDuration() external view returns (uint64);

    /*
     * @notice Calculates the current challenge period duration considering the number of operations in queue and the total number of active actors.
     *
     * @return uint64 representing the current challenge period duration.
     */
    function getCurrentChallengePeriodDuration() external view returns (uint64);

    /*
     * @notice Calculates the adjustment duration based on the total number of operations in queue.
     *
     * @return uint64 representing the adjustment duration based on the total number of operations in queue.
     */
    function getCurrentQueuedOperationsAdjustmentDuration() external view returns (uint64);

    /*
     * @notice Returns the pending challenge id for an actor in a given epoch.
     *
     * @param epoch
     * @param actor
     *
     * @return bytes32 representing the pending challenge id for an actor in a given epoch.
     */
    function getPendingChallengeIdByEpochOf(uint16 epoch, address actor) external view returns (bytes32);

    /*
     * @notice Returns the total number of actors in an epoch.
     *
     * @param epoch
     * @param actorType
     *
     * @return uint16 representing the total number of actors in an epoch.
     */
    function getTotalNumberOfActorsByEpochAndType(uint16 epoch, ActorTypes actorType) external view returns (uint16);

    /*
     * @notice Returns the total number of inactive actors in an epoch.
     *
     * @param epoch
     * @param actorType
     *
     * @return uint16 representing the total number of inactive actors in an epoch.
     */
    function getTotalNumberOfInactiveActorsByEpochAndType(
        uint16 epoch,
        ActorTypes actorType
    ) external view returns (uint16);

    /*
     * @notice Indicates if the protocol is in lockdown
     *
     * @return bool indicating if the protocol is in lockdown
     */
    function isLockedDown() external view returns (bool);

    /*
     * @notice Calculates the operation id.
     *
     * @param operation
     *
     * @return (bytes32) the operation id.
     */
    function operationIdOf(Operation memory operation) external pure returns (bytes32);

    /*
     * @notice Return the status of an operation.
     *
     * @param operation
     *
     * @return (OperationStatus) the operation status.
     */
    function operationStatusOf(Operation calldata operation) external view returns (OperationStatus);

    /*
     * @notice An actor instruct a cancel action. If 2 actors agree on it the operation is cancelled.
     *
     * @param operation
     * @param actorType
     * @param proof
     * @param signature
     *
     */
    function protocolCancelOperation(
        Operation calldata operation,
        ActorTypes actorType,
        bytes32[] calldata proof,
        bytes calldata signature
    ) external;

    /*
     * @notice Execute an operation that has been queued.
     *
     * @param operation
     *
     */
    function protocolExecuteOperation(Operation calldata operation) external payable;

    /*
     * @notice The Governance instruct a cancel action. If 2 actors agree on it the operation is cancelled.
     *          This function can be invoked ONLY by the DandelionVoting contract ONLY on the interim chain
     *
     * @param operation
     *
     */
    function protocolGovernanceCancelOperation(Operation calldata operation) external;

    /*
     * @notice Queue an operation.
     *
     * @param operation
     *
     */
    function protocolQueueOperation(Operation calldata operation) external payable;

    /*
     * @notice Slash a sentinel of a guardians previously challenges if it was not able to solve the challenge in time.
     *
     * @param challenge
     *
     */
    function slashByChallenge(Challenge calldata challenge) external;

    /*
     * @notice Solve a challenge of an actor and sends the bond (lockedAmountStartChallenge) to the DAO.
     *
     * @param challenge
     * @param actorType
     * @param proof
     * @param signature
     *
     */
    function solveChallenge(
        Challenge calldata challenge,
        ActorTypes actorType,
        bytes32[] calldata proof,
        bytes calldata signature
    ) external;

    /*
     * @notice Start a challenge for an actor.
     *
     * @param actor
     * @param actorType
     * @param proof
     *
     */
    function startChallenge(address actor, ActorTypes actorType, bytes32[] memory proof) external payable;

    /*
     * @notice Generate an user operation which will be used by the relayers to be able
     *         to queue this operation on the destination network through the StateNetwork of that chain
     *
     * @param destinationAccount
     * @param destinationNetworkId
     * @param underlyingAssetName
     * @param underlyingAssetSymbol
     * @param underlyingAssetDecimals
     * @param underlyingAssetTokenAddress
     * @param underlyingAssetNetworkId
     * @param assetTokenAddress
     * @param assetAmount
     * @param networkFeeAssetAmount
     * @param forwardNetworkFeeAssetAmount
     * @param userData
     * @param optionsMask
     */
    function userSend(
        string calldata destinationAccount,
        bytes4 destinationNetworkId,
        string calldata underlyingAssetName,
        string calldata underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId,
        address assetTokenAddress,
        uint256 assetAmount,
        uint256 networkFeeAssetAmount,
        uint256 forwardNetworkFeeAssetAmount,
        bytes calldata userData,
        bytes32 optionsMask
    ) external;
}
