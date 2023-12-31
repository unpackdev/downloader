// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ISSVNetwork.sol";

interface INodeStakingPool {
    receive() external payable;

    // GETTER FUNCTIONS
    function NodeLiquidETH() external view returns (address);

    function getWithdrawalAddress() external view returns (address);

    function getOperatorsPool() external view returns (uint256[] memory);

    function getFullValidatorsPool() external view returns (bytes[] memory);

    function getValidatorsPool() external view returns (bytes[] memory);

    function getValidatorIndexInPool(
        bytes memory _publicKey
    ) external view returns (uint256);

    function getUserShares(address _user) external view returns (uint256);

    function getUserAssets(address _user) external view returns (uint256);

    function sharesToAssets(uint256 _shares) external view returns (uint256);

    function getCurrentSharePrice() external view returns (uint256);

    function getPendingETHToStake() external view returns (uint256);

    function getUserPendingETHToStake() external view returns (uint256);

    function getTotalPoolRewards() external view returns (uint256);

    function getBeaconBalance() external view returns (uint256);

    function getexecutionRewards() external view returns (uint256);

    // MANAGEMENT FUNCTIONS
    function updateOperatorsPool(uint256[] memory _operators) external;

    function updateOracleStats(uint256 _beaconRewards, uint256 _rewards) external;

    function processWithdrawals() external;

    // PUBLIC FUNCTIONS
    function stake() external payable;

    function unstake(uint256 _shares) external;

    // Deposit validator to BeaconContract
    function depositToBeaconContract(
        bytes calldata _publicKey,
        bytes calldata _withdrawalCredentials,
        bytes calldata _signature,
        uint256 _amount,
        bytes32 _depositDataRoot
    ) external;

    function registerValidatorToSSVNetwork(
        bytes calldata _publicKey,
        uint64[] calldata _operatorIds,
        bytes calldata _shares,
        uint256 _amount,
        ISSVNetwork.Cluster memory _cluster
    ) external;

    // Remove validator from SSV Network
    function removeValidatorFromSSVNetwork(
        bytes memory _publicKey,
        uint64[] memory _operatorIds,
        ISSVNetwork.Cluster memory _cluster
    ) external;

    function updateTotalETHStaked(uint256 _amount) external;

    // TESTNET FUNCTIONS
    // remove validator from pool
    function removeValidatorFromPool(uint256 _index) external;

    // add validator to pool
    function addValidatorToPool(bytes memory _publicKey) external;

    function updateBeaconContract(address _beaconContract) external;

    // Withdraw SSV Tokens function
    function withdrawSSVTokens(uint256 _amount) external;

    // Withdraw ETH function
    function withdrawETH(uint256 _amount) external;

    // Function to deposit ETH and store them in withdrawal pool
    function depositETHToWithdrawalPool() external payable;

    // Function to withdraw ETH from the withdrawal pool. Owner can only withdraw ETH equal to withdrawalPool value
    function withdrawETHFromWithdrawalPool(uint256 _amount) external;
}
