// SPDX-License-Identifier: BSD-3-Clause
// Copyright © 2023 TXA PTE. LTD.
pragma solidity 0.8.19;

interface IAssetChainManager {
    function admin() external view returns (address);
    function portal() external view returns (address);
    function receiver() external view returns (address);
    function supportedAsset(address _asset) external view returns (bool);
    function getMinimumDeposit(address _asset) external view returns (uint256);
}
