// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Exchange.sol";
import "./ProxyRegistry.sol";
import "./MadworldTransferProxy.sol";
import "./ERC20.sol";
import "./RoyaltyFeeRegistry.sol";

contract MadworldExchange is Exchange {
    string public constant name = "Project Wyvern Exchange";

    /**
     * @dev Initialize a WyvernExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     * @param tokenAddress Address of the token used for protocol fees
     */
    constructor(
        ProxyRegistry registryAddress,
        MadworldTransferProxy tokenTransferProxyAddress,
        ERC20 tokenAddress,
        RoyaltyFeeRegistry royaltyFeeRegistryAddress
    ) {
        royaltyFeeRegistry = royaltyFeeRegistryAddress;
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
    }
}
