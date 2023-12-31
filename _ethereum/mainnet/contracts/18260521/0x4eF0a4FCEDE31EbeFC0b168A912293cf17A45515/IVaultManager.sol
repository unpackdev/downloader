// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVaultManager {

    function MEVVaultImplementation() external view returns(address);

    function JinoroFee() external view returns (uint256);

    function vaultToAccount(address user) external view returns (address);

    function accountToVault(address account) external view returns(address);

    function checkIfVaultBuilt(address account) external view returns (bool);

    function setMEVVaultImplementation(address impl) external;

    function setJinoroFee(uint256 newRate) external;

    function collectVaultRewards(address account) external;

    function collectVaultRewards() external;

    function collectVaultRewardsBulk(address[] calldata accounts) external;

    function buildVault(address account) external returns(address);

}
