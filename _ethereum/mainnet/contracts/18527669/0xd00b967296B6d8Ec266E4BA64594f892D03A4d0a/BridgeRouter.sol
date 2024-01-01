// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./OwnableUpgradeable.sol";

import "./ProofParser.sol";
import "./ICrossChainBridge.sol";
import "./SimpleTokenProxy.sol";
import "./InternetBondProxy.sol";

contract BridgeRouter {

    function peggedTokenAddress(address bridge, address fromToken) public pure returns (address) {
        return SimpleTokenProxyUtils.simpleTokenProxyAddress(bridge, bytes32(bytes20(fromToken)));
    }

    function peggedBondAddress(address bridge, address fromToken) public pure returns (address) {
        return InternetBondProxyUtils.internetBondProxyAddress(bridge, bytes32(bytes20(fromToken)));
    }

    function factoryPeggedToken(address fromToken, address toToken, ICrossChainBridge.Metadata memory metaData, address bridge) public returns (IERC20Mintable) {
        /* we must use delegate call because we need to deploy new contract from bridge contract to have valid address */
        address targetToken = SimpleTokenProxyUtils.deploySimpleTokenProxy(bridge, bytes32(bytes20(fromToken)), metaData);
        require(targetToken == toToken, "bad chain");
        /* to token is our new pegged token */
        return IERC20Mintable(toToken);
    }

    function factoryPeggedBond(address fromToken, address toToken, ICrossChainBridge.Metadata memory metaData, address bridge, address feed) public returns (IERC20Mintable) {
        /* we must use delegate call because we need to deploy new contract from bridge contract to have valid address */
        address targetToken = InternetBondProxyUtils.deployInternetBondProxy(bridge, bytes32(bytes20(fromToken)), metaData, feed);
        require(targetToken == toToken, "bad chain");
        /* to token is our new pegged token */
        return IERC20Mintable(toToken);
    }
}
