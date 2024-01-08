// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ISelfCompoundingYield {
    function baseAsset() external view returns (address);

    function deposit(uint256 baseAmount) external;
    function withdraw(uint256 shareAmount) external;
    function shareToBaseAsset(uint256 share) external view returns (uint256);
    function baseAssetToShare(uint256 baseAmount) external view returns (uint256);
}