// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "./SafeMathLib.sol";
import "./IERC20.sol";

contract BasicPoolFactory {
    using SafeMathLib for uint;

    struct Receipt {
        uint id;
        uint amountDepositedWei;
        uint timeDeposited;
        uint timeWithdrawn;
        address owner;
    }

    struct Pool {
        uint id;
        uint[] rewardsWeiPerSecondPerToken;
        uint[] rewardsWeiClaimed;
        uint maximumDepositWei;
        uint totalDepositsWei;
        uint numReceipts;
        uint startTime;
        uint endTime;
        address depositToken;
        address[] rewardTokens;
        mapping (uint => Receipt) receipts;
    }

    struct Metadata {
        bytes32 name;
        bytes32 ipfsHash;
    }

    uint public numPools;
    mapping (uint => Pool) public pools;
    mapping (uint => Metadata) public metadatas;

    address public management;

    event DepositOccurred(uint indexed poolId, uint indexed receiptId, address indexed owner);
    event WithdrawalOccurred(uint indexed poolId, uint indexed receiptId, address indexed owner);
    event ExcessRewardsWithdrawn(uint indexed poolId);
    event ManagementUpdated(address oldManagement, address newManagement);
    event PoolAdded(uint indexed poolId, bytes32 indexed name, address indexed depositToken);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor (address mgmt) {
        management = mgmt;
    }

    // change the management key
    function setManagement(address newMgmt) public managementOnly {
        address oldMgmt = management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    function addPool (
        uint startTime,
        uint maxDeposit,
        uint[] memory rewardsWeiPerSecondPerToken,
        uint programLengthDays,
        address depositTokenAddress,
        address[] memory rewardTokenAddresses,
        bytes32 ipfsHash,
        bytes32 name
    ) external managementOnly {
        numPools = numPools.plus(1);
        Pool storage pool = pools[numPools];
        pool.id = numPools;
        pool.rewardsWeiPerSecondPerToken = rewardsWeiPerSecondPerToken;
        pool.startTime = startTime > block.timestamp ? startTime : block.timestamp;
        pool.endTime = startTime.plus(programLengthDays * 1 days);
        pool.depositToken = depositTokenAddress;
        require(rewardsWeiPerSecondPerToken.length == rewardTokenAddresses.length, 'Rewards and reward token arrays must be same length');

        for (uint i = 0; i < rewardTokenAddresses.length; i++) {
            pool.rewardTokens.push(rewardTokenAddresses[i]);
            pool.rewardsWeiClaimed.push(0);
        }
        pool.maximumDepositWei = maxDeposit;

        {
            Metadata storage metadata = metadatas[numPools];
            metadata.ipfsHash = ipfsHash;
            metadata.name = name;
        }
        emit PoolAdded(pool.id, name, depositTokenAddress);
    }

    function getRewards(uint poolId, uint receiptId) public view returns (uint[] memory) {
        Pool storage pool = pools[poolId];
        Receipt memory receipt = pool.receipts[receiptId];
        require(pool.id == poolId, 'Uninitialized pool');
        require(receipt.id == receiptId, 'Uninitialized receipt');
        uint nowish = block.timestamp;
        if (nowish > pool.endTime) {
            nowish = pool.endTime;
        }

        uint secondsDiff = nowish.minus(receipt.timeDeposited);
        uint[] memory rewardsLocal = new uint[](pool.rewardsWeiPerSecondPerToken.length);
        for (uint i = 0; i < pool.rewardsWeiPerSecondPerToken.length; i++) {
            rewardsLocal[i] = (secondsDiff.times(pool.rewardsWeiPerSecondPerToken[i]).times(receipt.amountDepositedWei)) / 1e18;
        }

        return rewardsLocal;
    }

    function deposit(uint poolId, uint amount) external {
        Pool storage pool = pools[poolId];
        require(pool.id == poolId, 'Uninitialized pool');
        require(block.timestamp > pool.startTime, 'Cannot deposit before pool start');
        require(block.timestamp < pool.endTime, 'Cannot deposit after pool ends');
        require(pool.totalDepositsWei < pool.maximumDepositWei, 'Maximum deposit already reached');
        if (pool.totalDepositsWei.plus(amount) > pool.maximumDepositWei) {
            amount = pool.maximumDepositWei.minus(pool.totalDepositsWei);
        }
        pool.totalDepositsWei = pool.totalDepositsWei.plus(amount);
        pool.numReceipts = pool.numReceipts.plus(1);

        Receipt storage receipt = pool.receipts[pool.numReceipts];
        receipt.id = pool.numReceipts;
        receipt.amountDepositedWei = amount;
        receipt.timeDeposited = block.timestamp;
        receipt.owner = msg.sender;

        bool success = IERC20(pool.depositToken).transferFrom(msg.sender, address(this), amount);
        require(success, 'Token transfer failed');

        emit DepositOccurred(poolId, pool.numReceipts, msg.sender);
    }

    function withdraw(uint poolId, uint receiptId) external {
        Pool storage pool = pools[poolId];
        require(pool.id == poolId, 'Uninitialized pool');
        Receipt storage receipt = pool.receipts[receiptId];
        require(receipt.id == receiptId, 'Can only withdraw real receipts');
        require(receipt.owner == msg.sender || block.timestamp > pool.endTime, 'Can only withdraw your own deposit');
        require(receipt.timeWithdrawn == 0, 'Can only withdraw once per receipt');

        // close re-entry gate
        receipt.timeWithdrawn = block.timestamp;

        uint[] memory rewards = getRewards(poolId, receiptId);
        pool.totalDepositsWei = pool.totalDepositsWei.minus(receipt.amountDepositedWei);
        bool success = true;

        for (uint i = 0; i < rewards.length; i++) {
            pool.rewardsWeiClaimed[i] = pool.rewardsWeiClaimed[i].plus(rewards[i]);
            success = success && IERC20(pool.rewardTokens[i]).transfer(receipt.owner, rewards[i]);
        }
        success = success && IERC20(pool.depositToken).transfer(receipt.owner, receipt.amountDepositedWei);
        require(success, 'Token transfer failed');

        emit WithdrawalOccurred(poolId, receiptId, receipt.owner);
    }

    function withdrawExcessRewards(uint poolId) external {
        Pool storage pool = pools[poolId];
        require(pool.id == poolId, 'Uninitialized pool');
        require(pool.totalDepositsWei == 0, 'Cannot withdraw until all deposits are withdrawn');
        require(block.timestamp > pool.endTime, 'Contract must reach maturity');

        bool success = true;
        for (uint i = 0; i < pool.rewardTokens.length; i++) {
            IERC20 rewardToken = IERC20(pool.rewardTokens[i]);
            uint rewards = rewardToken.balanceOf(address(this));
            success = success && rewardToken.transfer(management, rewards);
        }
        IERC20 depositToken = IERC20(pool.depositToken);
        success = success && depositToken.transfer(management, depositToken.balanceOf(address(this)));
        require(success, 'Token transfer failed');
        emit ExcessRewardsWithdrawn(poolId);
    }

    function getRewardData(uint poolId) external view returns (uint[] memory, uint[] memory, address[] memory) {
        Pool storage pool = pools[poolId];
        return (pool.rewardsWeiPerSecondPerToken, pool.rewardsWeiClaimed, pool.rewardTokens);
    }

    function getReceipt(uint poolId, uint receiptId) external view returns (uint, uint, uint, address) {
        Pool storage pool = pools[poolId];
        Receipt storage receipt = pool.receipts[receiptId];
        return (receipt.amountDepositedWei, receipt.timeDeposited, receipt.timeWithdrawn, receipt.owner);
    }
}
