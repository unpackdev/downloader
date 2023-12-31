// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeMath.sol";

import "./IUniswapV2Router.sol";
import "./console.sol";

library Utils {
  using SafeMath for uint256;

  function random(
    uint256 from,
    uint256 to,
    uint256 salty
  ) private view returns (uint256) {
    uint256 seed = uint256(
      keccak256(
        abi.encodePacked(
          block.timestamp +
            block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
              (block.timestamp)) +
            block.gaslimit +
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
              (block.timestamp)) +
            block.number +
            salty
        )
      )
    );
    return seed.mod(to - from) + from;
  }

  function isLotteryWon(
    uint256 salty,
    uint256 winningDoubleRewardPercentage
  ) private view returns (bool) {
    uint256 luckyNumber = random(0, 100, salty);
    uint256 winPercentage = winningDoubleRewardPercentage;
    return luckyNumber <= winPercentage;
  }

  function calculateETHReward(
    uint256 currentBalance,
    uint256 currentETHPool,
    uint256 totalSupply
  ) public pure returns (uint256) {
    uint256 ethPool = currentETHPool;

    // now calculate reward
    uint256 reward = ethPool.mul(currentBalance).div(totalSupply);

    return reward;
  }

  function calculateTopUpClaim(
    uint256 currentRecipientBalance,
    uint256 basedRewardCycleBlock,
    uint256 threshHoldTopUpRate,
    uint256 amount
  ) public view returns (uint256) {
    if (currentRecipientBalance == 0) {
      return block.timestamp + basedRewardCycleBlock;
    } else {
      uint256 rate = amount.mul(100).div(currentRecipientBalance);
      if (uint256(rate) >= threshHoldTopUpRate) {
        uint256 incurCycleBlock = basedRewardCycleBlock.mul(uint256(rate)).div(
          100
        );
        console.log('basedRewardCycleBlock', basedRewardCycleBlock);
        console.log('incurCycleBlock', incurCycleBlock);
        if (incurCycleBlock >= basedRewardCycleBlock) {
          incurCycleBlock = basedRewardCycleBlock;
        }

        return incurCycleBlock;
      }

      return 0;
    }
  }

  function swapTokensForEth(
    address routerAddress,
    uint256 tokenAmount,
    address recipient
  ) public {
    IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

    // generate the pancake pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = router.WETH();
    // make the swap
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      recipient,
      block.timestamp + 20 * 60
    );
  }

  function swapETHForTokens(
    address routerAddress,
    address recipient,
    uint256 ethAmount
  ) public {
    IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

    // generate the pancake pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = router.WETH();
    path[1] = address(this);

    // make the swap
    router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
      0, // accept any amount of ETH
      path,
      address(recipient),
      block.timestamp + 360
    );
  }

  function addLiquidity(
    address routerAddress,
    address owner,
    uint256 tokenAmount,
    uint256 ethAmount
  ) public {
    IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

    // add the liquidity
    router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner,
      block.timestamp
    );
  }
}
