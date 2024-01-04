pragma solidity 0.5.16;

import "./IERC20.sol";
import "./IRewardDistributionRecipient.sol";


contract RewardsInitiator {
    string constant private ERROR_TOO_EARLY = "REWARDS_CTRL:TOO_EARLY";
    string constant private ERROR_ALREADY_INITIATED = "REWARDS_CTRL:ALREADY_INITIATED";

    uint256 public earliestStartTime;

    // Pools
    IRewardDistributionRecipient public uniPool;
    IRewardDistributionRecipient public bptPool;

    bool initiated;

    constructor(uint256 _earliestStartTime, address _uniPool, address _bptPool) public {
        earliestStartTime = _earliestStartTime;
        uniPool = IRewardDistributionRecipient(_uniPool);
        bptPool = IRewardDistributionRecipient(_bptPool);
    }

    function initiate() external {
        require(block.timestamp >= earliestStartTime, ERROR_TOO_EARLY);
        require(!initiated, ERROR_ALREADY_INITIATED);

        uint256 uniRewardBalance = poolRewardBalance(uniPool);
        uniPool.notifyRewardAmount(uniRewardBalance);

        uint256 bptRewardBalance = poolRewardBalance(bptPool);
        bptPool.notifyRewardAmount(bptRewardBalance);

        initiated = true;
    }

    function poolRewardBalance(IRewardDistributionRecipient _pool) public view returns (uint256) {
        IERC20 rewardToken = _pool.rewardToken();
        return rewardToken.balanceOf(address(_pool));
    }
}
