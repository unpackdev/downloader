// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./Initializable.sol";
import "./Exchange.sol";
import "./ProxyRegistry.sol";
import "./VindergoodTransferProxy.sol";
import "./ERC20.sol";

contract VindergoodExchange is Exchange {
    string public constant name = "Vindergood Exchange";

    /**
     * @dev Initialize a VindergoodExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     * @param tokenAddress Address of the token used for protocol fees
     */
    function initialize(
        ProxyRegistry registryAddress,
        VindergoodTransferProxy tokenTransferProxyAddress,
        ERC20 tokenAddress
    ) public initializer {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
    }
}
