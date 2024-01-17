pragma solidity ^0.8.0;

interface IRewards {
    function stake(address, uint256) external;

    function stake(uint256) external;

    function stakeFor(address, uint256) external;

    function withdraw(address, uint256) external;

    function exit(address) external;

    function getReward(bool) external;

    function getReward(address, bool) external returns(bool);

    function getReward() external returns (bool);

    function queueNewRewards(uint256) external;

    function notifyRewardAmount(uint256) external;

    function addExtraReward(address) external;

    function stakingToken() external returns (address);

    function withdraw(uint256, bool) external returns(bool);

    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);

    function earned(address account) external view returns (uint256);

    function depositAll(bool, address) external;

    function deposit(uint256, bool) external;
}
