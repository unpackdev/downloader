// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./PilgrimToken.sol";
import "./XPilgrim.sol";

struct Bridge {
    address from;
    address to;
    uint24 fee;
}

/// @notice Representation of a PIL lockup position. Internal purpose only
///
/// @param  amount  amount of xPIL tokens minted
///
/// @param  expiryDateTimestamp UNIX timestamp of which this lockup position expires and its underlying PIL tokens are available for
///
struct XPILLockupPosition {
    uint128 amount;
    uint64 expiryDateTimestamp; //
}

struct XPILLockupPositionQueue {
    uint128 head;
    uint128 tail;
    mapping(uint256 => XPILLockupPosition) positions;
}

struct AppStorage {
    mapping(address => Bridge) bridges;
    mapping(address => XPILLockupPositionQueue) queues;
    mapping(uint256 => mapping(address => bool)) transactionHistory;
    PilgrimToken pilgrim;
    XPilgrim xPilgrim;

    address treasury;

    uint32 lockupPeriod;
    uint32 subsidizationNumerator;
    uint32 subsidizationDenominator;
}

library LibAppStorage {
    function _diamondStorage() internal pure returns (AppStorage storage _ds) {
        assembly {
            _ds.slot := 0
        }
    }
}
