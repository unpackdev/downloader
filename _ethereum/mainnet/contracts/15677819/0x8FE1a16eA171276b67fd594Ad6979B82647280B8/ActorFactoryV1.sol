// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ActorFactoryOperationsUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title ActorFactoryTypehashesUpgradeable
 * @author NeatFi
 * @notice This contract holds the internal functions of the Actor Factory.
 */
contract ActorFactoryV1 is ActorFactoryOperationsUpgradeable, UUPSUpgradeable {
    string private name;
    string private currentVersion;

    /**
     * @dev Sets the version for the current implementation of this contract.
     */
    function _setVersion(string memory newVersion) internal {
        currentVersion = newVersion;
    }

    /**
     * @dev Requests the actor key. Can be called only from the NeatFi operations contract.
     * @param actorAddress - The address of the Actor contract.
     */
    function requestActorKey(address actorAddress)
        external
        onlyRole(AUTHORIZED_OPERATOR)
    {
        _requestActorKey(actorAddress);
    }

    /**
     * @dev Approves and generates an actor key. Can be executed by a Protocol Admin only.
     * @param actorAddress - The address of the Actor contract.
     */
    function approveAndGenerateActorKey(address actorAddress)
        external
        onlyRole(PROTOCOL_ADMIN)
        returns (bytes32 actorKey)
    {
        return _approveAndGenerateActorKey(actorAddress);
    }

    /**
     * @dev Activates an Actor. Can be executed by a Protocol Admin only.
     * @param actorAddress - The address of the Actor contract.
     */
    function activateActor(address actorAddress)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        _activateActor(actorAddress);
    }

    /**
     * @dev Inactivates an Actor. Can be executed by a Protocol Admin only.
     * @param actorAddress - The address of the Actor contract.
     */
    function inactivateActor(address actorAddress)
        external
        onlyRole(PROTOCOL_ADMIN)
    {
        _inactivateActor(actorAddress);
    }

    /**
     * @dev Retrieves the actor key based on the Actor contract address.
     * @param actorAddress - The address of the Actor contract.
     */
    function getActorKey(address actorAddress)
        external
        view
        returns (bytes32 actorKey)
    {
        return _getActorKey(actorAddress);
    }

    /**
     * @dev Retrieves the fee distribution address for an Actor.
     * @param actorAddress - The address of the Actor contract.
     * @return feeDistributionAddress - The receiver address
     *                                    of protocol fees.
     */
    function getFeeDistributionAddress(address actorAddress)
        external
        view
        onlyRole(AUTHORIZED_OPERATOR)
        returns (address payable feeDistributionAddress)
    {
        return _getFeeDistributionAddress(actorAddress);
    }

    /**
     * @dev Changes the fee distribution address for an Actor.
     * @param actorAddress - The address of the Actor contract.
     * @param newFeeDistributionAddress - The new receiver address
     *                                    of protocol fees.
     */
    function changeFeeDistributionAddress(
        address actorAddress,
        address payable newFeeDistributionAddress
    ) external onlyRole(AUTHORIZED_OPERATOR) {
        _changeFeeDistributionAddress(actorAddress, newFeeDistributionAddress);
    }

    /** Initializers */

    function _authorizeUpgrade(address newImplementation) internal override {}

    function initialize() public initializer onlyProxy {
        __UUPSUpgradeable_init();
        __ActorFactoryOperations_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        name = "NeatFi ActorKey Factory";
        _setVersion("1.0.0");
    }
}
