//SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

import "./StakingRewards.sol";

interface IBoardroom {
    /// Update accrued rewards for all tokens of owner
    /// @param owner address to update accruals
    function updateAccruals(address owner) external;
}

/// @title Rewards pool for distributing synthetic tokens
contract RewardsPool is StakingRewards {
    string public name;
    IBoardroom public boardroom;

    /// Creates a new contract.
    /// @param _name an address allowed to add rewards
    /// @param _owner an address allowed to add set reward period, recover funds and pause
    /// @param _rewardsDistribution an address allowed notify about new rewards and recalculate rate
    /// @param _rewardsToken token distributed to stakeholders
    /// @param _stakingToken token to be staked
    /// @param _rewardsDuration lifetime of the pool in seconds
    constructor(
        string memory _name,
        address _owner,
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken,
        uint256 _rewardsDuration
    )
        public
        StakingRewards(
            _owner,
            _rewardsDistribution,
            _rewardsToken,
            _stakingToken
        )
    {
        name = _name;
        rewardsDuration = _rewardsDuration;
    }

    function stake(uint256 amount) public {
        _updateBoardroomAccruals(msg.sender);
        super.stake(amount);
    }

    function withdraw(uint256 amount) public {
        _updateBoardroomAccruals(msg.sender);
        super.withdraw(amount);
    }

    function setBoardroom(address _boardroom) external onlyOwner {
        boardroom = IBoardroom(_boardroom);
        emit BoardroomChanged(msg.sender, _boardroom);
    }

    function _updateBoardroomAccruals(address owner) internal {
        if (address(boardroom) != address(0)) {
            boardroom.updateAccruals(owner);
        }
    }

    event BoardroomChanged(address indexed operator, address newBoardroom);
}
