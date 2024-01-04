pragma solidity 0.5.16;

interface IFeeRewardForwarder {
    function poolNotifyFixedTarget(address _token, uint256 _amount) external;
}
