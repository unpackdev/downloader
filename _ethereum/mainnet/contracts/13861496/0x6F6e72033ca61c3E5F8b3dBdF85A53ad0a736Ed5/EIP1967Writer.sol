/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./Address.sol";
import "./StorageSlot.sol";

import "./EIP1967Reader.sol";

abstract contract EIP1967Writer is EIP1967Reader {
    event Upgraded(address implementation);

    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        _initializeImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _setImplementation(address newImplementation) private {
        require(
            Address.isContract(newImplementation),
            "implementation is not a contract"
        );
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    function _initializeImplementation(address newImplementation) private {
        bytes memory data = abi.encodePacked(_INITIALIZE_CALL);
        Address.functionDelegateCall(newImplementation, data);
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode
