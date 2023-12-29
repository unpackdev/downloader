// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INonceContract {
    function outboundNonce(uint16 _chainId, bytes calldata _path) external view returns (uint64);
}
