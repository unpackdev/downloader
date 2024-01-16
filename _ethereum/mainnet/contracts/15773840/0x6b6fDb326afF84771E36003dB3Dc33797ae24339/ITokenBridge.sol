// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;


interface ITokenBridge {
    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) external view returns (address);
}
