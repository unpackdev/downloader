// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICollectionHelper {
    function getType(address collection) external view returns (uint8);

    function deploy(
        address owner,
        string memory name,
        string memory symbol,
        string memory uri,
        bool is721
    ) external returns (address);
}
