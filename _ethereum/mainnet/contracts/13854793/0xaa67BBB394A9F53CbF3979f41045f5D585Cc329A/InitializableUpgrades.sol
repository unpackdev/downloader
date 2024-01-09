/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./EIP1967Reader.sol";
import "./EIP1967Writer.sol";

abstract contract InitializableUpgrades is EIP1967Reader, EIP1967Writer {
    address private _implementationInitialized;

    modifier implementationInitializer() {
        require(
            _implementationInitialized != implementation(),
            "already upgraded"
        );

        _;

        _implementationInitialized = implementation();
    }

    // solhint-disable-next-line no-empty-blocks
    function initialize() external virtual implementationInitializer {}

    function implementation() public view returns (address) {
        return _implementationAddress();
    }

    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode
