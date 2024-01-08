// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract IO {
    function _readSlot(bytes32 _slot) internal view returns (bytes32 _data) {
        assembly {
            _data := sload(_slot)
        }
    }

    function _readSlotUint256(bytes32 _slot) internal view returns (uint256 _data) {
        assembly {
            _data := sload(_slot)
        }
    }

    function _readSlotAddress(bytes32 _slot) internal view returns (address _data) {
        assembly {
            _data := sload(_slot)
        }
    }

    function _writeSlot(bytes32 _slot, uint256 _data) internal {
        assembly {
            sstore(_slot, _data)
        }
    }

    function _writeSlot(bytes32 _slot, bytes32 _data) internal {
        assembly {
            sstore(_slot, _data)
        }
    }

    function _writeSlot(bytes32 _slot, address _data) internal {
        assembly {
            sstore(_slot, _data)
        }
    }
}
