// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeEndpoint {
    function send(uint16 dstChainId, address dstAddress, bytes memory payload) external payable returns (uint64);

    function estimateFee(uint16 dstChainId) external view returns (uint256 fee);

    function chainId() external view returns (uint16);
}
