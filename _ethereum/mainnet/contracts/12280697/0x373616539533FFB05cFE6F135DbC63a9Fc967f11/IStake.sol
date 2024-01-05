pragma solidity >=0.8.0;

interface IStake {
    function claim0(address _owner) external;

    function initialize(
        address stakeToken,
        address rewardToken,
        uint256 start,
        uint256 end,
        uint256 rewardPerBlock
    ) external;
}
