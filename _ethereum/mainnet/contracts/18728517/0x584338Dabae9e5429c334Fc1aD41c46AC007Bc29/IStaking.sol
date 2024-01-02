// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IStaking {
    function getStakerPrincipal(address _staker) external view returns (uint256);

    function getMaxPoolSize() external view returns (uint256);

    function getTotalPrincipal() external view returns (uint256);

    function getStakerLimits() external view returns (uint256, uint256);

    function getRewardVault() external view returns (address);

    function isActive() external view returns (bool);

    function getMerkleRoot() external view returns (bytes32);

    function migrate(bytes calldata data) external;
}
