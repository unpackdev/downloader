//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.2;

interface IMovieVotingMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that Stars distribution occurs.
        uint256 accStarsPerShare; // Accumulated Stars per share, times ACC_SUSHI_PRECISION. See below.
        uint256 poolSupply;
        uint256 rewardAmount;
        uint256 rewardAmountPerBlock;
        uint256 startBlock;
        uint256 endBlock;
    }

    function userInfo(uint256 pid, address user)
        external
        returns (uint256, uint256);

    function init(address _movieVotingAddress) external;

    function poolLength() external returns (uint256);

    function add(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rewardAmount,
        bool _withUpdate
    ) external;

    function pendingStars(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function accStarsPerShareAtCurrRate(
        uint256 blocks,
        uint256 rewardAmountPerBlock,
        uint256 poolSupply,
        uint256 startBlock,
        uint256 endBlock
    ) external returns (uint256);

    function starsPerBlock(uint256 pid) external returns (uint256);

    function updatePool(uint256 _pid) external;

    function massUpdatePools() external;

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _staker
    ) external;

    function withdraw(uint256 _pid, address _staker) external;

    function withdrawPartial(uint256 _pid, uint256 _amount, address _staker) external;

    function emergencyWithdraw(uint256 _pid, address _staker) external;

    function safeStarsTransfer(address _to, uint256 _amount) external;
}
