// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/// @title Oh! Finance Base Upgradeable
/// @notice Contains internal functions to get/set primitive data types used by a proxy contract
abstract contract OhUpgradeable {
    function getAddress(bytes32 slot) internal view returns (address _address) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _address := sload(slot)
        }
    }

    function getBoolean(bytes32 slot) internal view returns (bool _bool) {
        uint256 bool_;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            bool_ := sload(slot)
        }
        _bool = bool_ == 1;
    }

    function getBytes32(bytes32 slot) internal view returns (bytes32 _bytes32) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _bytes32 := sload(slot)
        }
    }

    function getUInt256(bytes32 slot) internal view returns (uint256 _uint) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _uint := sload(slot)
        }
    }

    function setAddress(bytes32 slot, address _address) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setBytes32(bytes32 slot, bytes32 _bytes32) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _bytes32)
        }
    }

    /// @dev Set a boolean storage variable in a given slot
    /// @dev Convert to a uint to take up an entire contract storage slot
    function setBoolean(bytes32 slot, bool _bool) internal {
        uint256 bool_ = _bool ? 1 : 0;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, bool_)
        }
    }

    function setUInt256(bytes32 slot, uint256 _uint) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _uint)
        }
    }
}
