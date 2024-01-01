// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IRewards.sol";
import "./ITokenLocker.sol";

/*
This is a utility library which is mainly used for off chain calculations
*/
contract Utilities{

    address public immutable cvxprismaStaking;
    address public immutable prismaLocker;
    address public immutable voteproxy;

    constructor(address _voteproxy, address _prismaLocker, address _staking) {
        voteproxy = _voteproxy;
        prismaLocker = _prismaLocker;
        cvxprismaStaking = _staking;
    }

    function lockedPrisma() external view returns(uint256){
        (uint256 lockedAmount,) = ITokenLocker(prismaLocker).getAccountBalances(voteproxy);
        return lockedAmount * ITokenLocker(prismaLocker).lockToTokenRatio();
    }


    //get apr with given rates and prices
    function apr(uint256 _rate, uint256 _priceOfReward, uint256 _priceOfDeposit) external pure returns(uint256 _apr){
        return _rate * 365 days * _priceOfReward / _priceOfDeposit; 
    }

    //get reward rates for each token based on weighted reward group supply and wrapper's boosted cvxcrv rates
    //%return = rate * timeFrame * price of reward / price of LP / 1e18
    function stakingRewardRates() external view returns (address[] memory tokens, uint256[] memory rates) {

        //get staked supply
        uint256 stakedSupply = IRewards(cvxprismaStaking).totalSupply();

        uint256 rewardTokens = IRewards(cvxprismaStaking).rewardTokenLength();

        tokens = new address[](rewardTokens);
        rates = new uint256[](rewardTokens);

        //loop through all reward contracts
        for (uint256 i = 0; i < rewardTokens; i++) {
            //get token
            tokens[i] = IRewards(cvxprismaStaking).rewardTokens(i);

            //get rate
            (uint256 periodFinish , uint256 rate, , ) = IRewards(cvxprismaStaking).rewardData(tokens[i]);
            
            if(block.timestamp > periodFinish){
                rate = 0;
            }

            //rate per 1 staked lp
            if(stakedSupply > 0){
                rate = rate * 1e18 / stakedSupply;
            }
            
            rates[i] = rate;
        }
    }
}
