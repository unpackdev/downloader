// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IUniswapV2Router02.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IWETH.sol";
import "./Rena.sol";
import "./IFeeDistributor.sol";
import "./ILPStaking.sol";
import "./IRebalancer.sol";

contract Rebalancer is IRebalancer, ReentrancyGuard {
    using SafeMath for uint256;
    Rena rena;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD; 

    uint256 public refillAmount;
    event Rebalanced(address indexed caller, uint256 reward, uint256 indexed stakeReward, uint256 indexed burned, uint256 renaswapDrip);
    constructor(address rena_) {
        rena = Rena(rena_);
   
    }
    //The Ethereum being accumulated here from the Claim is intended to refill the rebalancer.
    //The other ETH sent comes from RENA/rETH intended to purchase RENA and distribute to stakers.
    receive() external payable {
    }

    function refill() payable external override {
        require(msg.sender == rena.claim(), "Only claim can refill");
        refillAmount = refillAmount.add(msg.value);
    }

    function rebalance(uint16 callerRewardDivisor, uint16 rebalanceDivisor) override external nonReentrant {
        require(msg.sender == address(rena), "You aren't Rena");
        //The accumluated balance from any other address will buy RENA for Staking.
        address uniPair = rena.uniPair();
                
        uint256 liquidityRemoved = IERC20(uniPair).balanceOf(address(this)).div(rebalanceDivisor);
        remLiquidity(liquidityRemoved, uniPair);        
        uint256 reward = address(this).balance.sub(refillAmount) / rena.callerRewardDivisor();

        if(callerRewardDivisor > 0) {
            tx.origin.transfer(reward);
            rena.treasury().transfer(reward);
        }
        uint256 ethForStaking = IERC20(rena.WETH()).balanceOf(address(this));
        uint256 whole = address(this).balance.add(ethForStaking);
        
        //We need to buy Rena for the stakers, refill and rebalance effects.
        swapEthForRena(address(this).balance.sub(refillAmount).add(refillAmount.div(2)), ethForStaking);
        uint256 renaBought = rena.balanceOf(address(this));
        if(refillAmount > 0) {
            uint256 renaRefilled = renaBought.mul(refillAmount.div(2)).div(whole);
            rena.approve(rena.uniRouter(), renaRefilled);
            IUniswapV2Router02(rena.uniRouter()).addLiquidityETH{value:refillAmount.div(2)}(
                address(rena),
                renaRefilled,
                0,
                0,
                address(this),
                block.timestamp
            );
            refillAmount = 0;
        }
        address lpStaking = rena.lpStaking();
        uint256 stakeReward = renaBought.mul(ethForStaking).div(whole);
        rena.transfer(lpStaking, stakeReward);
        ILPStaking(lpStaking).addPendingRewards();
        ILPStaking(lpStaking).massUpdatePools();
        
        refillAmount = 0;

        uint256 remaining = rena.balanceOf(address(this));

        uint256 burned = remaining.div(5).mul(2);
        uint256 renaswapDrip = remaining.sub(burned);
        rena.transfer(burnAddress, burned);
        rena.transfer(rena.feeDistributor(), renaswapDrip);
        IFeeDistributor(rena.feeDistributor()).distributeFees(); //Depending on gas limits, this may have to be removed.
        emit Rebalanced(tx.origin, reward, stakeReward, burned, renaswapDrip);
    }

    function swapEthForRena(uint256 amount, uint256 wethForStaking) internal {
        address[] memory path = new address[](2);
        address WETH = rena.WETH();
        address router = rena.uniRouter();

        path[0] = WETH;
        path[1] = address(rena);

        IERC20(WETH).approve(router, amount.add(wethForStaking));
        IWETH(WETH).deposit{value:amount}();
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens
        (amount.add(wethForStaking), 0, path, address(this), block.timestamp);
    }

    function remLiquidity(uint256 amount_, address uniPair) internal returns(uint256 ethAmount) {
        address router = rena.uniRouter();
        IERC20(uniPair).approve(router, amount_);
        (ethAmount) = IUniswapV2Router02(router).removeLiquidityETHSupportingFeeOnTransferTokens(
            address(rena),
            amount_,
            0,
            0,
            address(this),
            block.timestamp
        );
    }    
    function sync() external {}
}