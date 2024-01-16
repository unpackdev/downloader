// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title ActorFactoryEventsUpgradeable
 * @author NeatFi
 * @notice This contract holds the events for the Actor Factory.
 */
contract ActorFactoryEventsUpgradeable is Initializable {
    /**
     * @dev Fired when an actor key is requested.
     * @param actorAddress - The address of the Actor contract.
     */
    event ActorKeyRequested(address actorAddress);

    /**
     * @dev Fired when the Actor is approved and the actor key is generated.
     * @param actorAddress - The address of the Actor contract.
     * @param actorKey - The actor key of the Actor.
     */
    event ActorKeyCreated(address actorAddress, bytes32 actorKey);

    /**
     * @dev Fired when the Actor is activated.
     * @param actorAddress - The address of the Actor contract.
     */
    event ActorActivated(address actorAddress);

    /**
     * @dev Fired when the Actor is inactivated.
     * @param actorAddress - The address of the Actor contract.
     */
    event ActorInactivated(address actorAddress);

    /* Initializers */

    function __ActorFactoryEvents_init() internal initializer {
        __ActorFactoryEvents_init_unchained();
    }

    function __ActorFactoryEvents_init_unchained() internal initializer {}
}
