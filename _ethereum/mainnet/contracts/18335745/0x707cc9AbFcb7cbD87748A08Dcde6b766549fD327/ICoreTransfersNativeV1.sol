// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICoreTransfersNativeV1 {
    receive() external payable;

    fallback(bytes calldata) external payable returns (bytes memory);
}
