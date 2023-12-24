// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./Counters.sol";
import "./PseudoRandomLib.sol";

library RoomNamingStorage {
    using Counters for Counters.Counter;

    bytes32 internal constant STORAGE_SLOT = keccak256("keepers.contracts.storage.room.naming");

    struct Layout {
        Counters.Counter specialTicketsCount;
        mapping(uint256 => string) baseRoomNames;
        mapping(uint256 => string) customRoomNames;
        mapping(uint256 => uint8) tokenIdToRoomRights;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
