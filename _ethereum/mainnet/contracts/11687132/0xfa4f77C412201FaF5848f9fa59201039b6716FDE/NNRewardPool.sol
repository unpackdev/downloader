// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./INestPool.sol";
import "./SafeERC20.sol";
import "./TransferHelper.sol";
import "./INestMining.sol";
import "./INNRewardPool.sol";

/// @title NNRewardPool
/// @author Inf Loop - <inf-loop@nestprotocol.org>
/// @author Paradox  - <paradox@nestprotocol.org>

/// @notice The NNRewardPool contract distributes the mining rewards,
///     15% share of the amount of nest-token produced by miners
/// @dev The nest-tokens are put in NestPool. This contract only traces 
///     the sum-amount of all of the rewards (nest-token)
///   - NNToken is pre-deployed in Nest v3.0, so we should connect (legacy)
///       with NNRewardPool. Whenever a NN holder transfers NN token to another,
///       NNToken will call back NNRewardPool.nodeCount() to settle rewards (decisively)
///       for both sender and receiver.
///   - After upgrading, NNRewardPool will count rewards from zero. Any NN holder should
///       claim rewards that had been issued before upgrading from the old contract. Old
///       data about NN rewards will be dropped in this contract, while it can also accessible
///       through OLD (Nest v3.0) contracts.
contract NNRewardPool is INNRewardPool {
    using SafeMath for uint256;

    /* ========== STATE ============== */

    uint8   public flag;     // | 1: active 
                            // | 0: uninitialized
                            // | 2: shutdown

    uint8   constant NNREWARD_FLAG_UNINITIALIZED    = 0;
    uint8   constant NNREWARD_FLAG_ACTIVE           = 1;
    uint8   constant NNREWARD_FLAG_PAUSED           = 2;

    uint256 public rewardSum;
    uint256 public totalSupplyNN;

    /// @dev From nest-node address to checkpoints of reward-sum
    mapping(address => uint256) public rewardSumCheckpoint;

    /* ========== ADDRESSES ============== */

    address public C_NNToken;
    address public C_NestToken;
    address public C_NestPool;
    address public C_NestMining;

    address public governance;


    /* ========== CONSTRUCTOR ========== */

    /// @notice Constructor of NNRewardPool contract
    /// @dev The NNToken contract was created on the Ethereum mainnet 
    /// @param NestPool The address of NestPool Contract
    /// @param NNToken The address of NestNode Token Contract
    constructor(address NestPool, address NNToken) public
    {
        C_NestPool = NestPool;
        C_NNToken = NNToken;
        totalSupplyNN = uint128(ERC20(C_NNToken).totalSupply());
        governance = msg.sender;
        flag = NNREWARD_FLAG_UNINITIALIZED;
    }

    function start() external onlyGovernance
    {
        require(flag == NNREWARD_FLAG_UNINITIALIZED, "Nest:NTC:!flag");

        flag = NNREWARD_FLAG_ACTIVE;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyBy(address _account)
    {
        require(msg.sender == _account, "Nest:NN:!Auth");
        _;
    }

    modifier noContract() 
    {
        require(address(msg.sender) == address(tx.origin), "Nest:NN:BAN(contract)");
        _;
    }

    modifier onlyGovernance() 
    {
        require(msg.sender == governance, "Nest:NN:!governance");
        _;
    }

    modifier onlyGovOrBy(address _account)
    {
        if (msg.sender != governance) { 
            require(msg.sender == _account,
                "Nest:NN:!Auth");
        }
        _;
    }

    /* ========== GOVERNANCE ========== */

    /// @dev To ensure that all of governance-addresses be consistent, every contract
    ///        besides NestPool must load newest `governance` from NestPool.
    function loadGovernance() override external 
    { 
        governance = INestPool(C_NestPool).governance();
    }

    /// @dev The function loads all nest-contracts, it is supposed to be called by NestPool
    function loadContracts() override external onlyGovOrBy(C_NestPool)
    {
        C_NestToken = INestPool(C_NestPool).addrOfNestToken();
        C_NNToken = INestPool(C_NestPool).addrOfNNToken();
        C_NestMining = INestPool(C_NestPool).addrOfNestMining();    

    }

    /// @dev Stop service for emergency
    function pause() external onlyGovernance
    {
        require(flag == NNREWARD_FLAG_ACTIVE, "Nest:NN:!flag");
        flag = NNREWARD_FLAG_PAUSED;
        emit FlagSet(address(msg.sender), uint256(NNREWARD_FLAG_PAUSED));
    }

    /// @dev Resume service 
    function resume() external onlyGovernance
    {
        require(flag == NNREWARD_FLAG_PAUSED, "Nest:NN:!flag");
        flag = NNREWARD_FLAG_ACTIVE;
        emit FlagSet(address(msg.sender), uint256(NNREWARD_FLAG_ACTIVE));
    }

    /* ========== ADDING REWARDS ========== */


    /// @notice Add rewards for Nest-Nodes, only NestMining (contract) are allowed
    /// @dev  The rewards need to pull from NestPool
    /// @param _amount The amount of Nest token as the rewards to each nest-node
    function addNNReward(uint256 _amount) override external onlyBy(C_NestMining)
    {
        if (_amount > 0) {
            uint256 _newSum = uint256(rewardSum).add(_amount);
            rewardSum = uint128(_newSum);
            emit NNRewardAdded(_amount, _newSum);
        }
        return;
    }

    // /// @dev The updator is to update the sum of NEST tokens mined in NestMining
    // function updateNNReward() external
    // {
    //     require(flag == NNREWARD_FLAG_ACTIVE, "Nest:NN:!flag");

    //     uint256 _allMined = INestMining(C_NestMining).minedNestAmount();
    //     if (_allMined > rewardSum) {
    //         uint256 _amount = _allMined.mul(NN_REWARD_PERCENTAGE).div(100).sub(rewardSum);
    //         uint256 _newSum = uint256(rewardSum).add(_amount);
    //         rewardSum = uint128(_newSum);
    //         emit NNRewardAdded(_amount, _newSum);
    //     }
    // }

    // modifier updateNNReward1()
    // {
    //     require(flag == NNREWARD_FLAG_ACTIVE, "Nest:NN:!flag");

    //     uint256 _allMined = INestMining(C_NestMining).minedNestAmount();
    //     if (_allMined > rewardSum) {
    //         uint256 _amount = _allMined.mul(NN_REWARD_PERCENTAGE).div(100).sub(rewardSum);
    //         uint256 _newSum = uint256(rewardSum).add(_amount);
    //         rewardSum = uint128(_newSum);
    //         emit NNRewardAdded(_amount, _newSum);
    //     }
    //    _;
    // }

    /* ========== CLAIM/SETTLEMENT ========== */

    /// @notice Claim rewards by Nest-Nodes
    /// @dev The rewards need to pull from NestPool
    function claimNNReward() override external noContract 
    {
        require(flag == NNREWARD_FLAG_ACTIVE, "Nest:NN:!flag");

        uint256 blnc =  ERC20(C_NNToken).balanceOf(address(msg.sender));
        require(blnc > 0, "Nest:NN:!(NNToken)");
        uint256 total = totalSupplyNN;
        uint256 sum = rewardSum;
        uint256 reward = sum.sub(rewardSumCheckpoint[address(msg.sender)]);
        uint256 share = reward.mul(blnc).div(total);

        rewardSumCheckpoint[address(msg.sender)] = sum;
        emit NNRewardClaimed(address(msg.sender), share);
     
        INestPool(C_NestPool).withdrawNest(address(this), share);
        require(ERC20(C_NestToken).transfer(address(msg.sender), share), "Nest:NN:!TRANS");
        
        return;
    }

    /// @notice Settle rewards for two NN holders
    /// @dev The function is for callback from NNToken. It is banned for contracts.
    /// @param from The address of the NN sender 
    /// @param to The address of the NN receiver 
    function settleNNReward(address from, address to) internal
    {
        require(flag == NNREWARD_FLAG_ACTIVE, "Nest:NN:!flag");

        uint256 fromBlnc = ERC20(C_NNToken).balanceOf(address(from));
        require (fromBlnc > 0, "Nest:NN:!(fromBlnc)");
        uint256 sum = rewardSum;
        uint256 total = totalSupplyNN;

        uint256 fromReward = sum.sub(rewardSumCheckpoint[from]).mul(fromBlnc).div(total);      
        rewardSumCheckpoint[from] = sum;      
       
        uint256 toBlnc = ERC20(C_NNToken).balanceOf(address(to));
        uint256 toReward = sum.sub(rewardSumCheckpoint[to]).mul(toBlnc).div(total);
        rewardSumCheckpoint[to] = sum;
        
        if (fromReward > 0) {
            INestPool(C_NestPool).withdrawNest(address(this), fromReward);
            require(ERC20(C_NestToken).transfer(from, fromReward), "Nest:NN:!TRANS");
            emit NNRewardClaimed(from, uint128(fromReward));
        }

        if (toReward > 0) { 
            INestPool(C_NestPool).withdrawNest(address(this), toReward);
            require(ERC20(C_NestToken).transfer(to, toReward), "Nest:NN:!TRANS");
            emit NNRewardClaimed(to, uint128(toReward));
        }

        return;
    }

    /// @dev The callback function called by NNToken.transfer()
    /// @param fromAdd The address of 'from' to transfer
    /// @param toAdd The address of 'to' to transfer
    function nodeCount(address fromAdd, address toAdd) 
        override
        external
        onlyBy(address(C_NNToken)) 
    {
        settleNNReward(fromAdd, toAdd);
        return;
    }

    /// @notice Show the amount of rewards unclaimed
    /// @return reward The reward of a NN holder
    function unclaimedNNReward() override external view returns (uint256 reward) 
    {
        uint256 blnc = ERC20(C_NNToken).balanceOf(address(msg.sender));
        uint256 sum = uint256(rewardSum);
        uint256 total = uint256(totalSupplyNN);
     
        reward = sum.sub(rewardSumCheckpoint[address(msg.sender)]).mul(blnc).div(total);
    }

}