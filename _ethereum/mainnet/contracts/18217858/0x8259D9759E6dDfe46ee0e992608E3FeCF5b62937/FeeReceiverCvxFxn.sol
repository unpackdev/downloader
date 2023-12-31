// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFeeReceiver.sol";
import "./IRewards.sol";
import "./IVoterProxy.sol";
import "./IBooster.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";



contract FeeReceiverCvxFxn is IFeeReceiver {
    using SafeERC20 for IERC20;

    address public constant fxn = address(0x365AccFCa291e7D3914637ABf1F7635dB165Bb09);
    address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address public constant cvxDistro = address(0x449f2fd99174e1785CF2A1c79E665Fec3dD1DdC6);
    address public immutable rewardAddress;
    address public immutable vefxnProxy;
    address public rewardToken;

    event RewardsDistributed(address indexed token, uint256 amount);
    event RewardTokenSet(address indexed token);

    constructor(address _rewardAddress, address _vefxnproxy) {
        rewardAddress = _rewardAddress;
        vefxnProxy = _vefxnproxy;
        IERC20(fxn).approve(rewardAddress, type(uint256).max);
        IERC20(cvx).approve(rewardAddress, type(uint256).max);
    }

    modifier onlyOwner() {
        require(IBooster(IVoterProxy(vefxnProxy).operator()).owner() == msg.sender, "!owner");
        _;
    }

    function setRewardToken(address _rToken) external onlyOwner{
        rewardToken = _rToken;
        IERC20(_rToken).approve(rewardAddress, 0);
        IERC20(_rToken).approve(rewardAddress, type(uint256).max);
        emit RewardTokenSet(_rToken);
    }

    function processFees() external {
        uint256 tokenbalance = IERC20(fxn).balanceOf(address(this));
       
        //process fxn
        if(tokenbalance > 0){
            //send to rewards
            IRewards(rewardAddress).notifyRewardAmount(fxn, tokenbalance);
            emit RewardsDistributed(fxn, tokenbalance);
        }

        IRewards(cvxDistro).getReward(address(this));
        tokenbalance = IERC20(cvx).balanceOf(address(this));
       
        //process cvx
        if(tokenbalance > 0){
            //send to rewards
            IRewards(rewardAddress).notifyRewardAmount(cvx, tokenbalance);
            emit RewardsDistributed(cvx, tokenbalance);
        }

        //process reward token
        if(rewardAddress != address(0)){
            tokenbalance = IERC20(rewardToken).balanceOf(address(this));
           
            if(tokenbalance > 0){
                //send to rewards
                IRewards(rewardAddress).notifyRewardAmount(rewardToken, tokenbalance);
                emit RewardsDistributed(rewardToken, tokenbalance);
            }
        }
    }

}