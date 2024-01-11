// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/***
 *    ╔╦╗╦ ╦╔═╗
 *     ║ ╠═╣║╣
 *     ╩ ╩ ╩╚═╝
 *    ╔═╗╔═╗╦  ╦  ╔═╗╔═╗╔╦╗╔═╗╦═╗╔═╗
 *    ║  ║ ║║  ║  ║╣ ║   ║ ║ ║╠╦╝╚═╗
 *    ╚═╝╚═╝╩═╝╩═╝╚═╝╚═╝ ╩ ╚═╝╩╚═╚═╝
 *    ╔╗╔╔═╗╔╦╗
 *    ║║║╠╣  ║
 *    ╝╚╝╚   ╩
 *    ╦  ╦╔═╗╦ ╦╦ ╔╦╗
 *    ╚╗╔╝╠═╣║ ║║  ║
 *     ╚╝ ╩ ╩╚═╝╩═╝╩
 *    ╔═╗╔═╗╔═╗╔╗╔╔═╗╔═╗╔═╗
 *    ║ ║╠═╝║╣ ║║║╚═╗║╣ ╠═╣
 *    ╚═╝╩  ╚═╝╝╚╝╚═╝╚═╝╩ ╩
 *    ╔═╗╔═╗╔═╗╔═╗╔╦╗
 *    ╠═╣╚═╗╚═╗║╣  ║
 *    ╩ ╩╚═╝╚═╝╚═╝ ╩
 *    ╔═╗╦═╗╔═╗═╗ ╦╦ ╦
 *    ╠═╝╠╦╝║ ║╔╩╦╝╚╦╝
 *    ╩  ╩╚═╚═╝╩ ╚═ ╩
 */

import "./TheCollectorsNFTVaultOpenseaAssetsHolderImpl.sol";

/*
    @dev
    The contract that will hold the assets and ETH for each vault.
    Working together with @TheCollectorsNFTVaultOpenseaAssetsHolderImpl in a proxy/implementation design pattern.
    The reason why it is separated to proxy and implementation is to save gas when creating vaults (reduced 50% gas)
*/
contract TheCollectorsNFTVaultOpenseaAssetsHolderProxy is Ownable, Proxy {

    // Must be in the same order as @TheCollectorsNFTVaultOpenseaAssetsHolderImpl
    address internal _proxyAddress;

    // For executing transactions
    address public target;
    bytes public data;
    uint256 public value;
    mapping(address => bool) public consensus;

    // ============ Proxy variables ============

    address public immutable implementation;

    function _implementation() override internal view virtual returns (address) {
        return implementation;
    }

    constructor(address impl) {
        implementation = impl;
        Address.functionDelegateCall(
            _implementation(),
            abi.encodeWithSelector(TheCollectorsNFTVaultOpenseaAssetsHolderImpl.init.selector)
        );
    }

    receive() override external payable {}
}

