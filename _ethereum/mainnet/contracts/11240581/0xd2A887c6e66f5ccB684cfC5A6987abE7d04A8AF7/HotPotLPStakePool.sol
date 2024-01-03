pragma solidity ^0.6.0;

import "./StakePool.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";


contract HotPotLPStakePool is StakePool{
    IUniswapV2Factory public uniswapFactory;

    constructor(
        address _hotpotNFT,
        address _hotpotERC20,
        address _loan,
        address _reward,
        address _invite,
        uint256 _starttime,
        uint256 duration,
        uint256 _rewardAmount,
        address _uniFactory,
        address _ethAddress
    ) public StakePool(_hotpotERC20,_hotpotNFT,_hotpotERC20,_loan,_reward,_invite,_starttime,duration,_rewardAmount){
        uniswapFactory = IUniswapV2Factory(_uniFactory != address(0) ? _uniFactory : 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); 

        address pair = uniswapFactory.createPair(_ethAddress,_hotpotERC20);
        tokenAddr = IERC20(pair);
    }
}