// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./StorageSlot.sol";
import "./Initializable.sol";

abstract contract Proxyable is Initializable {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    modifier onlyProxy() {
        require(_getImplementation() != address(0), "Must be called from proxy contract");
        _;
    }

    modifier onlyBeacon() {
        require(_getBeacon() != address(0), "Must be called from beacon contract");
        _;
    }

    function getRevision() external pure virtual returns (uint256) {
        return 0x1;
    }

    function _getImplementation() private view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }
}
