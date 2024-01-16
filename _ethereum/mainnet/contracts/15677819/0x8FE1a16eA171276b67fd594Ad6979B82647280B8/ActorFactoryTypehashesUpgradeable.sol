// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title ActorFactoryTypehashesUpgradeable
 * @author NeatFi
 * @notice This contract holds the typehashes for the Actor Factory.
 */
contract ActorFactoryTypehashesUpgradeable is Initializable {
    bytes32 constant ACTORKEY_TYPEHASH =
        keccak256(
            "Actor(address actorAddress, ActorStatus actorStatus, bytes32 actorKey)"
        );

    /* Initializers */

    function __ActorFactoryTypehashes_init() internal initializer {
        __ActorFactoryTypehashes_init_unchained();
    }

    function __ActorFactoryTypehashes_init_unchained() internal initializer {}
}
