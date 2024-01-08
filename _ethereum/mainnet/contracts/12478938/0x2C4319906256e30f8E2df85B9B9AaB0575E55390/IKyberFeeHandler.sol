pragma solidity 0.6.2;

interface IKyberFeeHandler {
    function claimStakerReward(
        address staker,
        uint256 epoch
    ) external returns(uint256 amountWei);
}
