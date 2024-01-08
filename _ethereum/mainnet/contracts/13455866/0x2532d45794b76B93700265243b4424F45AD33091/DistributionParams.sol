// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.9;

import "./ERC20PresetMinterPauser.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IStakingPool.sol";

contract DistributionParams {
  using SafeERC20 for IERC20;

  struct StakingPool {
    address poolAddress;
    uint rewardAmount;
  }

  struct Swap {
    address origin;
    address target;
    address pool;
    uint amount;
  }

  StakingPool[] public stakingPools;

  mapping (address => bool) public canSwap;

  uint public distributionPeriod = 29 days;
  uint public lastDistribution;

  IStakingPool public constant singleStaking = IStakingPool(0x79876b5062160C107e02826371dD33c047CCF2de);

  ERC20PresetMinterPauser public constant cmp = ERC20PresetMinterPauser(0x9f20Ed5f919DC1C1695042542C13aDCFc100dcab);
  IERC20 public constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  // Uniswap initially
  IUniswapV2Router02 public usdcToCmpRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  // CMP multisig initially
  address public gov = 0xa6423a1624712351c9b8C8bb4F5aA36B4C39B338;

  // CMP deployer initially
  address public sidechainDistributor = 0x45fE418D510594F7110963A0241B8E2962c97358;

  modifier g() {
    require(msg.sender == gov, "Distribution: !gov");
    _;
  }

  modifier s() {
    require(canSwap[msg.sender], "FeeDistribution: can't swap");
    _;
  }

  function setGov(address _gov) external g {
    gov = _gov;
  }

  function approveTokens() public {
    usdc.safeApprove(address(usdcToCmpRouter), type(uint).max);
  }

  function setParams(address _usdcToCmpRouter, StakingPool[] calldata _stakingPools, uint _distributionPeriod, address _sidechainDistributor) external g {
    usdcToCmpRouter = IUniswapV2Router02(_usdcToCmpRouter);
    usdc.safeApprove(address(usdcToCmpRouter), type(uint).max);
    delete stakingPools;
    for (uint i = 0; i < _stakingPools.length; i ++) {
      stakingPools.push(_stakingPools[i]);
    }
    distributionPeriod = _distributionPeriod;
    sidechainDistributor = _sidechainDistributor;
  }

  function usdcToCMPPath() public pure returns(address[] memory path) {
    path = new address[](3);
    path[0] = address(usdc);
    path[1] = weth;
    path[2] = address(address(cmp));
  }
}
