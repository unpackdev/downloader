// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
    UnstructuredStorageWithTimelock is a set of functions that facilitates setting/fetching unstructured storage 
    along with information of future updates and its timelock information.

    For every content storage, there are two other slots that could be calculated automatically:
        * Slot (The current value)
        * Scheduled Slot (The future value)
        * Scheduled Time (The future time)

    Note that the library does NOT enforce timelock and does NOT store the timelock information.
*/
library UnstructuredStorageWithTimelock {
    // This is used to calculate the time slot and scheduled content for different variables
    uint256 private constant SCHEDULED_SIGNATURE = 0x111;
    uint256 private constant TIMESLOT_SIGNATURE = 0xAAA;

    function updateAddressWithTimelock(bytes32 _slot) internal {
        require(
            scheduledTime(_slot) > block.timestamp,
            "Timelock has not passed"
        );
        setAddress(_slot, scheduledAddress(_slot));
    }

    function updateUint256WithTimelock(bytes32 _slot) internal {
        require(
            scheduledTime(_slot) > block.timestamp,
            "Timelock has not passed"
        );
        setUint256(_slot, scheduledUint256(_slot));
    }

    function setAddress(bytes32 _slot, address _target) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_slot, _target)
        }
    }

    function fetchAddress(bytes32 _slot)
        internal
        view
        returns (address result)
    {
        assembly {
            result := sload(_slot)
        }
    }

    function scheduledAddress(bytes32 _slot)
        internal
        view
        returns (address result)
    {
        result = fetchAddress(scheduledContentSlot(_slot));
    }

    function scheduledUint256(bytes32 _slot)
        internal
        view
        returns (uint256 result)
    {
        result = fetchUint256(scheduledContentSlot(_slot));
    }

    function setUint256(bytes32 _slot, uint256 _target) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_slot, _target)
        }
    }

    function fetchUint256(bytes32 _slot)
        internal
        view
        returns (uint256 result)
    {
        assembly {
            result := sload(_slot)
        }
    }

    function scheduledContentSlot(bytes32 _slot)
        internal
        pure
        returns (bytes32)
    {
        return
            bytes32(
                uint256(keccak256(abi.encodePacked(_slot, SCHEDULED_SIGNATURE)))
            );
    }

    function scheduledTime(bytes32 _slot) internal view returns (uint256) {
        return fetchUint256(scheduledTimeSlot(_slot));
    }

    function scheduledTimeSlot(bytes32 _slot) internal pure returns (bytes32) {
        return
            bytes32(
                uint256(keccak256(abi.encodePacked(_slot, TIMESLOT_SIGNATURE)))
            );
    }
}
