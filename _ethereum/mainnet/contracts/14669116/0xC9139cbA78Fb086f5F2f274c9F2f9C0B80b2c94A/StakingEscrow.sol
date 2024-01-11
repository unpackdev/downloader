pragma solidity ^0.8.12;

interface StakingEscrow {
    struct StakerInfo {
        uint256 value;
        uint16 currentCommittedPeriod;
        uint16 nextCommittedPeriod;
        uint16 lastCommittedPeriod;
        uint16 stub1; // former slot for lockReStakeUntilPeriod
        uint256 completedWork;
        uint16 workerStartPeriod; // period when worker was bonded
        address worker;
        uint256 flags; // uint256 to acquire whole slot and minimize operations on it
        uint256 vestingReleaseTimestamp;
        uint256 vestingReleaseRate;
        address stakingProvider;
    }

    function getStakersLength() external view returns(uint256);
    function stakerInfo(address _staker) external view returns(StakerInfo memory);
    function stakers(uint256 _index) external view returns(address);
}
