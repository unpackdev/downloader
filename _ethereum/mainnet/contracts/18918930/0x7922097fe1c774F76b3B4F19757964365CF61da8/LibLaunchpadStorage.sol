// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./DataType.sol";


library LibLaunchpadStorage {

    uint256 constant STORAGE_ID_LAUNCHPAD = 2 << 128;

    struct Storage {
        mapping(address => bool) administrators;

        // bytes4(launchpadId) + bytes1(slotId) + bytes27(0)
        mapping(bytes32 => DataType.LaunchpadSlot) launchpadSlots;

        // bytes4(launchpadId) + bytes1(slotId) + bytes7(0) + bytes20(accountAddress)
        mapping(bytes32 => DataType.AccountSlotStats) accountSlotStats;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_LAUNCHPAD }
    }
}
