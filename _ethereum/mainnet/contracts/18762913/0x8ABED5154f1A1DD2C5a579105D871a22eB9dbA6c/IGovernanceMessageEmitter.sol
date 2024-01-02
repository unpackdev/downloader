// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IPNetworkHub.sol";

/**
 * @title IGovernanceMessageEmitter
 * @author pNetwork
 *
 * @notice
 */

interface IGovernanceMessageEmitter {
    /**
     * @dev Emitted when actors are emitted.
     *
     * @param epoch The epoch
     * @param actors The actors
     * @param actorsType The actor types
     */
    event ActorsPropagated(uint16 indexed epoch, address[] actors, IPNetworkHub.ActorTypes[] actorsType);

    /**
     * @dev Emitted when a governance message must be propagated on the other chains
     *
     * @param data The data
     */
    event GovernanceMessage(bytes data);

    /*
     * @notice Emit a GovernanceMessage event containing the total number of actors (sentinels and guardians) and
     *         the actors merkle root for the current epoch. This message will be verified by GovernanceMessageVerifier.
     *
     * @param sentinels
     * @param guardians
     */
    function propagateActors(address[] calldata sentinels, address[] calldata guardians) external;

    /*
     * @notice Emit a GovernanceMessage to cancel an operation on a given network
     *
     * @param operation
     * @param networkId
     */
    function protocolGovernanceCancelOperation(IPNetworkHub.Operation calldata operation, bytes4 networkId) external;

    /*
     * @notice Emit a GovernanceMessage event containing the address and the type of the resumed actor
     *
     * @param actor
     * @param registrationKind
     */
    function resumeActor(address actor, bytes1 registrationKind) external;

    /*
     * @notice Emit a GovernanceMessage event containing the address and the type of the slashed actor
     *
     * @param actor
     * @param registrationKind
     */
    function slashActor(address actor, bytes1 registrationKind) external;
}
