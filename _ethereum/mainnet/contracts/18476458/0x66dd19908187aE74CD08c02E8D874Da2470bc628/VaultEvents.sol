// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract VaultEvents {
    event InitVault(
        address indexed operator,
        uint40 maxFundraisingPeriod,
        bytes32 indexed domainSeparator,
        bytes32 indexed executeTypeHash
    );
    event CreateStv(
        bytes32 indexed metadataHash,
        address indexed stvId,
        address indexed manager,
        uint40 endTime,
        uint96 capacityOfStv
    );
    event Deposit(address indexed stvId, address indexed caller, address indexed investor, uint96 amount);
    event DepositWithSubscription(
        address indexed stvId, address indexed caller, address indexed investor, uint96 amount
    );
    event Liquidate(address indexed stvId, uint8 status);
    event Execute(
        address indexed stvId,
        uint96 amount,
        uint96 totalReceived,
        uint256 command,
        bytes data,
        uint256 msgValue,
        bool isIncrease
    );
    event Distribute(
        address indexed stvId, uint96 totalRemainingAfterDistribute, uint96 mFee, uint96 pFee, uint256 command
    );
    event Cancel(address indexed stvId, uint8 status);
    event MaxFundraisingPeriod(uint40 maxFundraisingPeriod);
    event ClaimRewards(address indexed stvId, uint256 command, bytes indexed rewardData);
}
