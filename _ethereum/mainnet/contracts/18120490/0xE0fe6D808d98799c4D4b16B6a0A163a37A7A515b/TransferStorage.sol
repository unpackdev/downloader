// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./EnumerableSet.sol";

using EnumerableSet for EnumerableSet.AddressSet;

struct TransferStorage {
    EnumerableSet.AddressSet transferManagers;
}

bytes32 constant _TRANSFER_STORAGE = keccak256(
    "gelato.diamond.transfer.storage"
);

function _addTransferManager(address _manager) returns (bool) {
    return _transferStorage().transferManagers.add(_manager);
}

function _removeTransferManager(address _manager) returns (bool) {
    return _transferStorage().transferManagers.remove(_manager);
}

function _transferManagerAt(uint256 _index) view returns (address) {
    return _transferStorage().transferManagers.at(_index);
}

function _transferManagers() view returns (address[] memory) {
    return _transferStorage().transferManagers.values();
}

function _numberOfTransferManagers() view returns (uint256) {
    return _transferStorage().transferManagers.length();
}

function _isTransferManager(address _manager) view returns (bool) {
    return _transferStorage().transferManagers.contains(_manager);
}

//solhint-disable-next-line private-vars-leading-underscore
function _transferStorage() pure returns (TransferStorage storage ts) {
    bytes32 position = _TRANSFER_STORAGE;
    assembly {
        ts.slot := position
    }
}
