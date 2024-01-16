// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";

/**
 * @title ActorFactoryEnumsUpgradeable
 * @author NeatFi
 * @notice This contract holds the status enums for the Actor.
 */
contract ActorFactoryEnumsUpgradeable is Initializable {
    enum ActorStatus {
        // 0 - The actor key is requested by an Actor but is not yet generated.
        REQUESTED,
        // 1 - The actor key is approved by NeatFi and the Actor is active.
        ACTIVE,
        // 2 - The Actor is inactive.
        INACTIVE
    }

    /* Initializers */

    function __ActorFactoryEnums_init() internal initializer {
        __ActorFactoryEnums_init_unchained();
    }

    function __ActorFactoryEnums_init_unchained() internal initializer {}
}
