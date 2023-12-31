// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

interface ICoreMulticallV1 {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    function getBalance(address assetAddress) external view returns (uint256);
}
