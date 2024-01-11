// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library RouteStorage {

    bytes32 public constant ptSlot = keccak256("RouteStorage.storage.location");

    struct Route {
        address [] allowInputs;
        address [] allowOutputs;
        mapping(address => mapping(address => bytes)) swapRoute;
    }

    function load() internal pure returns (Route storage pt) {
        bytes32 loc = ptSlot;
        assembly {
            pt.slot := loc
        }
    }
}
