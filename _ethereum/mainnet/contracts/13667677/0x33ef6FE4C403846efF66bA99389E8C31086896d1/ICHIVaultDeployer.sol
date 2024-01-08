// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface ICHIVaultDeployer {
    function owner() external view returns (address);

    function CHIManager() external view returns (address);

    function setOwner(address _owner) external;

    function setCHIManager(address _manager) external;

    function createVault(
        address uniswapV3pool,
        address manager,
        uint256 fee
    ) external returns (address pool);

    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event CHIManagerChanged(
        address indexed oldCHIManager,
        address indexed newCHIManager
    );
}
