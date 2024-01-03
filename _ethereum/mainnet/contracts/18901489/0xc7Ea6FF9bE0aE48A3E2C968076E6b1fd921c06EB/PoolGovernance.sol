// SPDX-License-Identifier: Apache-2.0
// Copyright 2022-2023 Smoothly Protocol LLC
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./SmoothlyPool.sol";

/// @title Smoothing Pool Governance Contract
/// @notice This contract is in charge of receiving votes from operator
/// nodes with the respective withdrawals, exits and state root hashes of the
/// computed state for every epoch. Reach consensus and pass the data to the
/// SmoothlyPool contract.
contract PoolGovernance is Ownable {
    uint8 internal constant votingRatio = 66; // % of agreements required
    uint32 public epochInterval = 7 days;
    uint64 public epochNumber;
    uint64 public lastEpoch;
    address[] public operators;
    SmoothlyPool public pool;

    /// @notice Epoch data to update the Smoothly Pool state
    /// @param withdrawals Merkle root hash for withdrawals
    /// @param exits Merkle root hash for exits
    /// @param state MPT root hash of entire state
    /// @param fee distributed to operators to keep network alive
    struct Epoch {
        bytes32 withdrawals;
        bytes32 exits;
        bytes32 state;
        uint256 fee;
    }

    /// @dev checks if operator is active
    mapping(address => bool) public isOperator;
    /// @dev records operator accumulative rewards
    mapping(address => uint256) public operatorRewards;
    /// @dev records operator votes for each epochNumber
    mapping(uint256 => mapping(address => bytes32)) public votes;
    /// @dev counts number of votes for each epochNumber
    mapping(uint256 => mapping(bytes32 => uint256)) public voteCounter;

    error ExistingOperator(address operator);
    error Unauthorized();
    error EpochTimelockNotReached();
    error ZeroAmount();
    error CallTransferFailed();
    error NotEnoughOperators();

    /// @dev restrict calls only to operators
    modifier onlyOperator() {
        if (!isOperator[msg.sender]) revert Unauthorized();
        _;
    }

    constructor(address[] memory _operators, SmoothlyPool _pool) {
        lastEpoch = uint64(block.timestamp);
        address(_pool) == address(0)
          ? pool = new SmoothlyPool() 
          : pool = SmoothlyPool(_pool);
        _addOperators(_operators);
    }

    /// @dev Receives fees from Smoothly Pool
    receive() external payable {
        if (msg.sender != address(pool)) revert Unauthorized();
    }

    /// @notice Gets all active operators
    /// @return All active operators
    function getOperators() external view returns (address[] memory) {
        return operators;
    }

    /// @notice withdraws accumulated rewards from an operator
    function withdrawRewards() external onlyOperator {
        uint256 rewards = operatorRewards[msg.sender];
        operatorRewards[msg.sender] = 0;

        if (rewards == 0) revert ZeroAmount();
        (bool sent, ) = msg.sender.call{value: rewards}("");
        if (!sent) revert CallTransferFailed();
    }

    /// @notice Proposal Data for current epoch computed from every operator
    /// @dev operators need to reach an agreement of at least votingRatio
    /// and no penalties are added for bad proposals or no proposals as admin
    /// have the abilities to delete malicious operators
    /// @param epoch Data needed to update Smoothly Pool state
    function proposeEpoch(Epoch calldata epoch) external onlyOperator {
        if (block.timestamp < lastEpoch + epochInterval)
            revert EpochTimelockNotReached();

        bytes32 vote = keccak256(abi.encode(epoch));
        bytes32 prevVote = votes[epochNumber][msg.sender];
        uint256 operatorsLen = operators.length;

        if(operatorsLen == 1) revert NotEnoughOperators();

        votes[epochNumber][msg.sender] = vote;

        if (prevVote != bytes32(0)) --voteCounter[epochNumber][prevVote];

        uint256 count = ++voteCounter[epochNumber][vote];
        if (((count * 100) / operatorsLen) >= votingRatio) {
            pool.updateEpoch(
                epoch.withdrawals,
                epoch.exits,
                epoch.state,
                epoch.fee
            );

            uint256 operatorShare = epoch.fee / operatorsLen;
            address[] memory _operators = operators;
            for (uint256 i = 0; i < operatorsLen; ++i) {
                operatorRewards[_operators[i]] += operatorShare;
            }

            ++epochNumber;
            lastEpoch = uint64(block.timestamp);
        }
    }

    /// @notice Adds operators
    /// @param _operators List of new operators
    function addOperators(address[] calldata _operators) external onlyOwner {
        _addOperators(_operators); 
    }

    /// @notice Deletes operators
    /// @param _operators List of operators to be removed
    function deleteOperators(address[] calldata _operators) external onlyOwner {
        for (uint256 i = 0; i < _operators.length; ++i) {
            isOperator[_operators[i]] = false;
            uint256 operatorsLen = operators.length;
            for (uint256 x = 0; x < operatorsLen; ++x) {
                if (operators[x] == _operators[i]) {
                    operators[x] = operators[operatorsLen - 1];
                    operators.pop();
                    // Transfer rewards to pool
                    uint256 rewards = operatorRewards[_operators[i]];
                    operatorRewards[_operators[i]] = 0;
                    if (rewards != 0) {
                      (bool sent, ) = address(pool).call{value: rewards}("");
                      if (!sent) revert CallTransferFailed();
                    }
                    break;
                }
            }
        }
    }

    /// @notice Transfers Ownership of Smoothly Pool
    /// @param newOwner owner to transfer ownership to
    function transferPoolOwnership(address newOwner) external onlyOwner {
        pool.transferOwnership(newOwner);
    }

    /// @notice Changes epochInterval timelock value
    /// @param interval updates epochInterval
    function updateInterval(uint32 interval) external onlyOwner {
      epochInterval = interval;
    }

    /// @notice Adds operators
    /// @param _operators List of new operators
    function _addOperators(address[] memory _operators) internal {
        for (uint256 i = 0; i < _operators.length; ++i) {
            if (isOperator[_operators[i]])
                revert ExistingOperator(_operators[i]);
            isOperator[_operators[i]] = true;
            operators.push(_operators[i]);
        }
    }
}
