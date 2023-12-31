// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeMath.sol";
import "./IUniswapV2Router.sol";

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

  function calculateETHRewardGamble(
    uint256 currentBalance,
    uint256 currentETHPool,
    uint256 totalSupply
  ) public view returns (uint256) {
    uint256 ethPool = currentETHPool;

    uint256 reward = 0;
    // calculate reward to send
    bool isLotteryWonOnClaim = isLotteryWon(
      currentBalance,
      50
    );
    if (isLotteryWonOnClaim) {
      reward = ethPool.mul(2).mul(currentBalance).div(
        totalSupply
      );
    }
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
        if (incurCycleBlock >= basedRewardCycleBlock) {
          incurCycleBlock = basedRewardCycleBlock;
        }

        return incurCycleBlock;
      }

      return 0;
    }
  }

  function doNothing() private pure returns (bool) {
    return true;
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
}
