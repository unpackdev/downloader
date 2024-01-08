pragma solidity ^0.8.0;

interface IDaoStakeContract {
    struct StakerData {
        uint256 altQuantity;
        uint256 initiationTimestamp;
        uint256 durationTimestamp;
        uint256 rewardAmount;
        address staker;
    }

    event StakeCompleted(
        bytes32 stakeID,
        uint256 altQuantity,
        uint256 initiationTimestamp,
        uint256 durationTimestamp,
        uint256 rewardAmount,
        address staker,
        address phnxContractAddress,
        address portalAddress
    );

    event Unstake(
        bytes32 stakeID,
        address staker,
        address stakedToken,
        address portalAddress,
        uint256 altQuantity,
        uint256 durationTimestamp
    ); // When ERC20s are withdrawn

    event BaseInterestUpdated(uint256 _newRate, uint256 _oldRate);
    event QuantityUpdated(uint256 _newQuantity, uint256 _oldQuanitity);
    event StakeDaysUpdated(uint256 _newdays, uint256 _oldDays);

    function stakeFor(
        uint256 _altQuantity,
        uint256 _time,
        address _beneficiary
    ) external returns (uint256 rewardAmount);

    function stakeALT(uint256 _altQuantity, uint256 _time) external returns (uint256 rewardAmount);

    function unstakeALT(bytes32[] calldata _expiredStakeIds, uint256 _amount) external returns (uint256);
}
