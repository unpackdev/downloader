// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./IUniswap.sol";
import "./RefillableStakingPool.sol";
import "./TokenDistribution.sol";

// import "./Babylonian.sol";
library Babylonian {
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
    // else z = 0
  }
}

contract UniswapStakingPool is RefillableStakingPool {
  using Address for address;

  TokenDistribution private immutable  gemlyOffering;

  uint256 constant          MAX_UINT      = 2**256 - 1;
  uint256 private constant  UNITIME       = 15 minutes;
  uint256 private constant  DECIMALS      = 10**18;
  address private constant  UNIROUTER     = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant  FACTORY       = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address private           WETHAddress   = IUniswap(UNIROUTER).WETH();

  constructor(address _governance, address _coreToken, address _rewardToken, address payable _offering) public
    RefillableStakingPool(_governance, _coreToken, _rewardToken) {
      gemlyOffering = TokenDistribution(_offering);
  }

  function init() external payable onlyGovernance {
    require(address(lpToken) == address(0), "LP already defined");
    require(address(this).balance > 0, "Balance is zero");
    require(coreToken.allowance(msg.sender, address(this)) > 0, "Token balance is zero");

    coreToken.approve(UNIROUTER, MAX_UINT);
    rewardToken.approve(UNIROUTER, MAX_UINT);

    uint256 allowed = coreToken.allowance(msg.sender, address(this));
    coreToken.safeTransferFrom(msg.sender, address(this), allowed);

    IUniswap(UNIROUTER).addLiquidityETH{value: address(this).balance}(address(coreToken), allowed, 0, 0, msg.sender, now + UNITIME);
    lpToken = IERC20(IUniswap(FACTORY).getPair(address(coreToken), WETHAddress));

    sendDust();
  }

  function stakeWithEth() external payable updateReward(msg.sender) nonReentrant {
    require(address(this).balance > 0, "Cannot stake 0");

    (bool inOffering, uint256 amountEth) = canSwapInOffering();
    uint256 amount = inOffering ? swapInOffering(amountEth) : swapInUni();
    
    (,,uint256 lpAmount) = IUniswap(UNIROUTER).addLiquidityETH{value: address(this).balance}(address(coreToken), amount, 0, 0, address(this), now + UNITIME);
    super.addStakeBalance(msg.sender, lpAmount);
    sendDust();

    emit Staked(msg.sender, lpAmount);
  }

  function uniReserve() internal view returns (uint256, uint256) {
    (uint112 reserve0, uint112 reserve1, ) = IUniswap(address(lpToken)).getReserves();
    if(IUniswap(address(lpToken)).token0() == address(coreToken)) {
      return (reserve0, reserve1);
    } else {
      return (reserve1, reserve0);
    }
  }

  function canSwapInOffering() internal view returns (bool, uint256) {
    (uint256 uniCore, uint256 uniEth) = uniReserve();
    uint256 offeringEth = DECIMALS;
    uint256 offeringCore = gemlyOffering.offerInEth(offeringEth);

    uint256 uniPrice = (DECIMALS).mul(uniEth).div(uniCore);
    uint256 offeringPrice = (DECIMALS).mul(offeringEth).div(offeringCore);

    if(uniPrice < offeringPrice) {
      return (false, 0);  
    }

    uint256 amountEth = offeringEth.mul(uniCore).mul(address(this).balance).div(offeringEth.mul(uniCore).add(offeringCore.mul(uniEth)));
    if(gemlyOffering.canBuyWithEth(amountEth)) {
      return (true, amountEth);  
    }
    return (false, 0);
  }

  function swapInOffering(uint256 amount) internal returns(uint256) {
    uint256 result = gemlyOffering.offerInEth(amount);
    gemlyOffering.buyWithEth{value: amount}();
    return result;
  }

  function swapInUni() internal returns(uint256) {
    (,uint256 reserveIn) = uniReserve();
    uint256 swapInAmount = Babylonian.sqrt(reserveIn.mul(address(this).balance.mul(3988000) + reserveIn.mul(3988009))).sub(reserveIn.mul(1997)) / 1994;

    address[] memory path = new address[](2);
    path[0] = WETHAddress;
    path[1] = address(coreToken);

    uint256[] memory result = IUniswap(UNIROUTER).swapExactETHForTokens{value: swapInAmount}(0, path, address(this), now + UNITIME);
    return result[1];
  }

  function sendDust() internal {
    if(coreToken.balanceOf(address(this)) > 0) {
      coreToken.safeTransfer(msg.sender, coreToken.balanceOf(address(this)));
    }
    if(address(this).balance > 0) {
      (bool success, ) = msg.sender.call{ value: address(this).balance }("");
      require(success, "Dust transfer failed");
    }
  }

  receive() external payable { }
}