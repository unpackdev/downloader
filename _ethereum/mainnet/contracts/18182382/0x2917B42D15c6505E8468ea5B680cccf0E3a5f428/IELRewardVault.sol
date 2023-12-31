// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IELRewardVault {
    /// @notice Thrown when over limit
    error OverMaxLimit();

    /// @notice Thrown when update operatorPartOne or operatorPartTwo
    error InvalidRoleSet();

    /// @notice Thrown when a function is called by an address that is not the current operator
    error NotOperator();

    /// @notice Thrown when zero value is set 
    error ZeroValueSet();

    /// @notice Thrown when values are set repeatedly
    error RepeatSetup();

    /// @notice Thrown when update fee point but new fee point over base point
    error InvalidFeePoint();

    /// @notice Each user's EL reward must be less than the contract ETH balance
    error RewardTooLarge();

    /// @notice Thrown when operator want sign same transaction 
    error NotSignTwice();

    /// @notice Thrown when migrate fund if valid fun is zero
    error NotFund();

    /// @notice Thrown when update users` ELReward info but requestId is zero
    error EmptyELRewardInfo();

    /// @notice Emitted when a new commissionPct is updated
    /// @param newCommissionPct New commissionPct
    event UpdateCommissionPct(uint256 newCommissionPct);

    /// @notice Emitted when a new commission receiver address is updated
    /// @param newCommissionReceiver New commission receiver address
    event UpdateCommissionReceiver(address newCommissionReceiver);

    /// @notice Emitted when a new operatorPartOne address is updated
    /// @param newOperatorPartOne New OperatorPartOne
    event UpdateOperatorPartOne(address newOperatorPartOne);

    /// @notice Emitted when a new operatorPartTwo address is updated
    /// @param newOperatorPartTwo New OperatorPartTwo
    event UpdateOperatorPartTwo(address newOperatorPartTwo);

    /// @notice Emitted when a new maxLimit threshold is updated
    /// @param newMaxLimit New maxLimit
    event UpdateMaxLimit(uint256 newMaxLimit);

    /// @notice Emitted when submit users` ELReward info
    event SubmitELRewardInfo(address operatorAddress, userInfo[] usersInfo, uint256 currentNextId);

    /// @notice Emitted when one of operator send distributeReward transaction
    event SignTransaction(address signerAddress, bool signStatus);

    /// @notice Emitted when another operator confirm distributeReward transaction
    event ExecTransaction(address execAddress, uint256 currentNextId);

    /// @notice Emitted when distribute users reward
    /// @param userAddress User's address
    /// @param ETHAmount User's ETH reward
    event UserRewardDistributed(address userAddress, uint256 ETHAmount);

    /// @notice Emitted when users claim their reward
    /// @param commissionReceiver commission fee receiver address
    /// @param ETHAmount ETH paid by the users
    event CommissionFeeTransferred(address commissionReceiver, uint256 ETHAmount);

    /// @notice Emitted when contract owner mi
    event MigrateFund(address senderAddress, address toAddress,uint256 migrateETHAmount);

    /// @notice Emitted when init operator sign status
    event InitSignStatus(address operatorAddr, bool signStatus);

    struct userInfo {
        address withdrawAddress;
        uint256 ELReward;
    }
}