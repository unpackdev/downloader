// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAssetDeployCode {
    function newAsset(bytes32 salt) external returns (address);
}
