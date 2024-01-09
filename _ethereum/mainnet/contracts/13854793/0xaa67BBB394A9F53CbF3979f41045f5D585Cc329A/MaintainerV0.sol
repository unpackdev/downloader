/**
 * Submitted for verification at Etherscan.io on 2021-12-23
 */

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";

import "./InitializableUpgrades.sol";
import "./ToonTokenMaintainerAccess.sol";

contract MaintainerV0 is
    OwnableUpgradeable,
    InitializableUpgrades,
    ToonTokenMaintainerAccess
{
    function upgrade(address newImplementation) external onlyOwner {
        _upgradeTo(newImplementation);
    }

    function initialize()
        external
        virtual
        override
        initializer
        implementationInitializer
    {
        __Ownable_init();
    }

    function onlyAuthorized() public virtual override returns (bool) {
        return owner() == _msgSender();
    }
}

// Copyright 2021 ToonCoin.COM
// http://tooncoin.com/license
// Full source code: http://tooncoin.com/sourcecode
