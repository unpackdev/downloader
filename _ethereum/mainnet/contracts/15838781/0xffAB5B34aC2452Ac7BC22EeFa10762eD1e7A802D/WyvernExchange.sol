
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "./Exchange.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title WyvernExchange
 * @author Project Wyvern Developers, JungleNFT Developers
 */
contract WyvernExchangeWithBulkCancellations is Exchange, UUPSUpgradeable {
    // string public constant CODENAME = "Bulk Smash";

    /**
     * @dev Initialize a WyvernExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     */
    function initialize(
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        address _contractOwner
    ) external initializer {
        require(_contractOwner != address(0), "Invalid owner");
        __ExchangeCore_init_();
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        _transferOwnership(_contractOwner);
    }

    //Only owner function for upgrading proxy.
    function _authorizeUpgrade(address) internal override onlyOwner {}
}