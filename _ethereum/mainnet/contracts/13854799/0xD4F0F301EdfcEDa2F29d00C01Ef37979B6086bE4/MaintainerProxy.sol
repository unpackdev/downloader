/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./Proxy.sol";
import "./Address.sol";

import "./EIP1967Reader.sol";

contract MaintainerProxy is EIP1967Reader, Proxy {
    constructor(address implementationAddress) {
        require(
            Address.isContract(implementationAddress),
            "implementation is not a contract"
        );

        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = implementationAddress;

        bytes memory data = abi.encodePacked(_INITIALIZE_CALL);
        Address.functionDelegateCall(implementationAddress, data);
    }

    function implementation() external view returns (address) {
        return _implementationAddress();
    }

    function _implementation() internal view override returns (address) {
        return _implementationAddress();
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode
