// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

import "./TokenTransferProxy.sol";

contract WyvernTokenTransferProxy is
    TokenTransferProxy,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    function initialize(ProxyRegistry registryAddr, address _contractOwner) external initializer {
        require(_contractOwner != address(0), "Invalid owner");
        __Ownable_init();
        registry = registryAddr;
        _transferOwnership(_contractOwner);
    }

    //Only owner function for upgrading proxy.
    function _authorizeUpgrade(address) internal override onlyOwner {}
}