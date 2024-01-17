// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Exchange.sol";
import "./ProxyRegistry.sol";
import "./PlaygroundTransferProxy.sol";
import "./RoyaltyFeeRegistry.sol";

contract PlaygroundExchange is Exchange {
    string public constant name = "Playground Exchange";

    /**
     * @dev Initialize a WyvernExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     */
    constructor(
        ProxyRegistry registryAddress,
        PlaygroundTransferProxy tokenTransferProxyAddress,
        RoyaltyFeeRegistry royaltyFeeRegistryAddress
    ) {
        royaltyFeeRegistry = royaltyFeeRegistryAddress;
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
    }
}
