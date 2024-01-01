// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface INonceCounter {
    /* ----- Events ----- */

    event CrossChainRouterUpdated(address crossChainRouter, bool flag);

    /* ----- State Variables ----- */

    function isCrossChainRouter(address sender) external view returns (bool flag);

    function outboundNonce(uint16 dstChainId) external view returns (uint256 nonce);

    /* ----- Functions ----- */

    function increment(uint16 dstChainId) external returns (uint256 nonce);
}
