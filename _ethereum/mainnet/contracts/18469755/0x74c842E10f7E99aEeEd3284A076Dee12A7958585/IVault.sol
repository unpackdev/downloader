// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IVault{
    function owner() external view returns(address);
    function getImplementation() external view returns(address);
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
    function execute(address dest, uint256 value, bytes calldata func) external returns(bytes memory);
    function executeBatch(address[] calldata dest, bytes[] calldata func) external returns(bytes[] memory);   
}