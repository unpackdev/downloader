// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";
import "./ActorFactoryEnumsUpgradeable.sol";

/**
 * @title ActorFactoryStorageUpgradeable
 * @author NeatFi
 * @notice This contract holds the storage for the Actor Factory.
 */
contract ActorFactoryStorageUpgradeable is
    Initializable,
    ActorFactoryEnumsUpgradeable
{
    /**
     * @dev The Actor struct.
     * @param actorContract - The address of the Actor contract.
     * @param actorStatus - The enum status of the Actor.
     *                      0 - REQUESTED,
     *                      1 - ACTIVE,
     *                      2 - INACTIVE.
     */
    struct Actor {
        /**
         * This is the address of the Actor contract implementation of NeatFi
         * modules that will interact with the NeatFi protocol through
         * the actor key.
         */
        address actorContract;
        /**
         * This is the address that will receive protocol fees. Can be
         * either a contract address as well. At the moment of the actor creation
         * this address is the same as the actor contract address. Actors are
         * able to change this address afterwards.
         */
        address payable feeDistributionAddress;
        // Actor status.
        ActorStatus actorStatus;
        // Actor key for the Actor contract address.
        bytes32 actorKey;
    }

    /**
     * @dev Mapping to hold the Actor info. The info is retrieved via the Actor address.
     */
    mapping(address => Actor) public actorInfo;

    /* Initializers */

    function __ActorFactoryStorage_init() internal initializer {
        __ActorFactoryStorage_init_unchained();
        __ActorFactoryEnums_init();
    }

    function __ActorFactoryStorage_init_unchained() internal initializer {}
}
