pragma solidity 0.6.12;

import "./SafeMath.sol";

interface IStakePoolRewardRebaser {
    function getRebaseAmount(address rewardToken, uint baseAmount) external view returns (uint);
}

interface RebaseToken {
    function totalSupply() external view returns (uint256);
    function totalShares() external view returns (uint256);
}

contract ValueBaseStakePoolRebaser is IStakePoolRewardRebaser {
    using SafeMath for uint;

    function getRebaseAmount(address rewardToken, uint shares) external override view returns (uint) {
        return shares.mul( RebaseToken(rewardToken).totalSupply() ).div( RebaseToken(rewardToken).totalShares() );
    }
}