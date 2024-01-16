// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ActorFactoryStorageUpgradeable.sol";
import "./ActorFactoryEventsUpgradeable.sol";
import "./ActorFactoryTypehashesUpgradeable.sol";
import "./RoleConstantsUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

/**
 * @title ActorFactoryOperationsUpgradeable
 * @author NeatFi
 * @notice This contract holds the operations for the Actor Factory.
 */
contract ActorFactoryOperationsUpgradeable is
    ActorFactoryStorageUpgradeable,
    ActorFactoryEventsUpgradeable,
    ActorFactoryTypehashesUpgradeable,
    RoleConstantsUpgradeable,
    AccessControlUpgradeable
{
    /**
     * @dev Requests the actor Key. Creates an Actor struct record without
     *      generating the actor key.
     * @param actorAddress - The address of the Actor contract.
     */
    function _requestActorKey(address actorAddress) internal {
        require(
            actorAddress.code.length > 0,
            "ActorFactoryOperationsUpgradeable::_requestActorKey: actor address is not a smart contract."
        );

        Actor memory actor = Actor(
            actorAddress,
            payable(actorAddress),
            ActorStatus.REQUESTED,
            0x0
        );

        actorInfo[actorAddress] = actor;

        emit ActorKeyRequested(actorAddress);
    }

    /**
     * @dev Approves and generates the actor Key. Updates the Actor struct record with
     *      the generated actor key. Updates the Actor status to ACTIVE.
     * @param actorAddress - The address of the Actor contract.
     * @return actorKey - The generated actor key.
     */
    function _approveAndGenerateActorKey(address actorAddress)
        internal
        returns (bytes32 actorKey)
    {
        require(
            actorInfo[actorAddress].actorKey == 0x0,
            "ActorFactoryOperationsUpgradeable::_approveAndGenerateActorKey: actor key already generated."
        );

        actorInfo[actorAddress].actorKey = keccak256(
            abi.encode(ACTORKEY_TYPEHASH, actorAddress)
        );
        actorInfo[actorAddress].actorStatus = ActorStatus.ACTIVE;

        emit ActorKeyCreated(actorAddress, actorInfo[actorAddress].actorKey);

        return actorKey;
    }

    /**
     * @dev Activates an inactive Actor. Updates the Actor status to ACTIVE.
     * @param actorAddress - The address of the Actor contract.
     */
    function _activateActor(address actorAddress) internal {
        require(
            actorInfo[actorAddress].actorKey != 0x0,
            "ActorFactoryOperationsUpgradeable::_activateActor: actor is not approved yet."
        );

        require(
            actorInfo[actorAddress].actorStatus == ActorStatus.INACTIVE,
            "ActorFactoryOperationsUpgradeable::_activateActor: actor is already active."
        );

        actorInfo[actorAddress].actorStatus = ActorStatus.ACTIVE;

        emit ActorActivated(actorAddress);
    }

    /**
     * @dev Inactivates an active Actor. Updates the Actor status to INACTIVE.
     * @param actorAddress - The address of the Actor contract.
     */
    function _inactivateActor(address actorAddress) internal {
        require(
            actorInfo[actorAddress].actorKey != 0x0,
            "ActorFactoryOperationsUpgradeable::_inactivateActor: actor is not approved yet."
        );

        require(
            actorInfo[actorAddress].actorStatus == ActorStatus.ACTIVE,
            "ActorFactoryOperationsUpgradeable::_inactivateActor: actor is already inactive."
        );

        actorInfo[actorAddress].actorStatus = ActorStatus.INACTIVE;

        emit ActorInactivated(actorAddress);
    }

    /**
     * @dev Retrieves the actor key for a given Actor address.
     * @param actorAddress - The address of the Actor contract.
     * @return actorKey - The generated actor key.
     */
    function _getActorKey(address actorAddress)
        internal
        view
        returns (bytes32 actorKey)
    {
        Actor memory actor = actorInfo[actorAddress];

        require(
            actor.actorKey != 0x0,
            "ActorFactoryOperationsUpgradeable::_getActorKey: actor key is 0x0."
        );

        return actor.actorKey;
    }

    /**
     * @dev Retrieves the actor protocol fee distribution address
     *      for a given Actor address.
     * @param actorAddress - The address of the Actor contract.
     * @return feeDistributionAddress - The fee distribution address.
     */
    function _getFeeDistributionAddress(address actorAddress)
        internal
        view
        returns (address payable feeDistributionAddress)
    {
        Actor storage actor = actorInfo[actorAddress];
        return actor.feeDistributionAddress;
    }

    /**
     * @dev Changes the actor protocol fee distribution address
     *      for a given Actor address.
     * @param actorAddress - The address of the Actor contract.
     * @param newFeeDistributionAddress - The new address to receive
     *                                    protocol fees.
     */
    function _changeFeeDistributionAddress(
        address actorAddress,
        address payable newFeeDistributionAddress
    ) internal {
        Actor storage actor = actorInfo[actorAddress];

        require(
            actor.actorKey != 0x0,
            "ActorFactoryOperationsUpgradeable::_changeFeeDistributionAddress: actor key is 0x0."
        );

        actor.feeDistributionAddress = newFeeDistributionAddress;
    }

    /** Initializer */

    function __ActorFactoryOperations_init() internal initializer {
        __ActorFactoryStorage_init();
        __ActorFactoryEvents_init();
        __ActorFactoryTypehashes_init();
        __RoleConstants_init();
        __AccessControl_init();
    }
}
