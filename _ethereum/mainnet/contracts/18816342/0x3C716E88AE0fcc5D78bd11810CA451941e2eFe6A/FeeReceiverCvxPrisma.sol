// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IFeeReceiver.sol";
import "./IRewards.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";



contract FeeReceiverCvxPrisma is IFeeReceiver {
    using SafeERC20 for IERC20;

    address public immutable rewardToken;
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant cvxDistro = address(0x449f2fd99174e1785CF2A1c79E665Fec3dD1DdC6);
    address public immutable rewardAddress;

    event RewardsDistributed(address indexed token, uint256 amount);

    constructor(address _rewardToken, address _rewardAddress) {
        rewardToken = _rewardToken;
        rewardAddress = _rewardAddress;
        IERC20(rewardToken).approve(rewardAddress, type(uint256).max);
        IERC20(cvx).approve(rewardAddress, type(uint256).max);
    }

    function processFees() external {
        uint256 tokenbalance = IERC20(rewardToken).balanceOf(address(this));
       
        //process rewardToken
        if(tokenbalance > 0){
            //send to rewards
            IRewards(rewardAddress).notifyRewardAmount(rewardToken, tokenbalance);
            emit RewardsDistributed(rewardToken, tokenbalance);
        }

        IRewards(cvxDistro).getReward(address(this));
        tokenbalance = IERC20(cvx).balanceOf(address(this));
       
        //process cvx
        if(tokenbalance > 0){
            //send to rewards
            IRewards(rewardAddress).notifyRewardAmount(cvx, tokenbalance);
            emit RewardsDistributed(cvx, tokenbalance);
        }
    }

    function onProcessFees(address _caller) external{
        
    }

}