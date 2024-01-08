// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./Rena.sol";

contract FeeDistributor is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => uint256) public weight;
    mapping(address => uint256) public index;

    address[] public weightedPairs;

    uint256 public maxPairs;
    uint256 public maxWeight;

    Rena rena;
    address public ITS;

    constructor(address rena_, address its_) {
        rena = Rena(rena_);
        ITS = its_;
    }
    
    receive() external payable {
    }
    // Add a pair to the list. This creats O(n) complexity so care needs to be had.
    // Offset index by 1. 0 will be used to determined if it's unset.
    function addPair(address pair_, uint256 weight_) external onlyOwner {
        require(weight_ > 0);
        maxPairs = maxPairs.add(1);
        maxWeight = maxWeight.add(weight_);
        weightedPairs.push(pair_);
        index[pair_] = maxPairs;
        weight[pair_] = weight_;
    }

    function alterWeight(address pair_, uint256 weight_) external onlyOwner {
        maxWeight = maxWeight.sub(weight[pair_]);
        maxWeight = maxWeight.add(weight_);
        weight[pair_] = weight_;
    }

    // Attrify the list by subtracting weight and moving the last object in its place.
    function removePair(address pair_) external onlyOwner {
        if(index[pair_] == 0 || maxPairs == 0) revert("No Such Pair");
        maxWeight = maxWeight.sub(weight[pair_]);
        weight[pair_] = 0;
        if(index[pair_] != maxPairs)
            weightedPairs[index[pair_]-1] = weightedPairs[maxPairs-1];
        weightedPairs.pop();
        maxPairs = maxPairs.sub(1);
        index[pair_] = 0;
    }

    function calculateFee(address pair_, uint256 amount) public view returns(uint256 fee) {
        fee = amount.mul(weight[pair_]).div(maxWeight);
    }

    //This function could fail if too many coins are added. removePair should always be able to recover.

    // All the RENA accumulating here comes from Rena Rebalancer & TX Fees.
    // Send that out based on weight.
    // ETH Collected here comes from ITS/rETH to buy 50% ITS, Setup LP and off to ITS Rebalancer.
    
    function distributeFees() external nonReentrant {
        uint256 feesToDistribute = rena.balanceOf(address(this));
        assert(maxWeight > 0);
        if(feesToDistribute > 0) {
            for(uint256 i; i < maxPairs ; i++) {
                uint256 fee = calculateFee(weightedPairs[i], feesToDistribute);
                if(fee == 0) continue;
                rena.transfer(weightedPairs[i], fee);
                IUniswapV2Pair(weightedPairs[i]).sync();
            }
        }        
        uint256 wethForSwap = IERC20(rena.WETH()).balanceOf(address(this)).div(2);
        if(wethForSwap > 0) {
            swapWethForIts(wethForSwap);
            IERC20(ITS).approve(rena.uniRouter(), IERC20(ITS).balanceOf(address(this)));
            IUniswapV2Router02(rena.uniRouter()).addLiquidity(
                rena.WETH(),
                ITS,
                wethForSwap,
                IERC20(ITS).balanceOf(address(this)),
                0,
                0,
                ITS,
                block.timestamp
            );        
        }
    }
    
    function swapWethForIts(uint256 amount) internal {
        address[] memory path = new address[](2);
        address router = rena.uniRouter();
        path[0] = rena.WETH();
        path[1] = ITS;

        //Get approval * 2 so we don't need to do it again for addLiquidity
        IERC20(path[0]).approve(router, amount.mul(2));
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens
        (amount, 0, path, address(this), block.timestamp);

    }    

    function sync() external {}
}