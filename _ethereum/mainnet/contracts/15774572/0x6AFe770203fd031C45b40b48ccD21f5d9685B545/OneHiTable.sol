// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.9;

import "./Proxy.sol";
import "./StorageSlot.sol";
import "./Address.sol";

contract OneHiTable is Proxy {

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(
        address _implAddr
    ) {
        _setImplementation(_implAddr);
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

}