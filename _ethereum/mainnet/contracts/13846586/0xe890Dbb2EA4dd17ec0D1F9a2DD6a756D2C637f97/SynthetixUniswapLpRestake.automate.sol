// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./Automate.sol";
import "./IStorage.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IStaking.sol";
import "./ERC20Tools.sol";

// solhint-disable not-rely-on-time
contract SynthetixUniswapLpRestake is Automate {
  using ERC20Tools for IERC20;

  IStaking public staking;

  address public liquidityRouter;

  uint16 public slippage;

  uint16 public deadline;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _info) Automate(_info) {}

  function init(
    address _staking,
    address _liquidityRouter,
    uint16 _slippage,
    uint16 _deadline
  ) external initializer {
    require(
      !_initialized || address(staking) == _staking,
      "SynthetixUniswapLpRestake::init: reinitialize staking address forbidden"
    );
    staking = IStaking(_staking);
    require(
      !_initialized || liquidityRouter == _liquidityRouter,
      "SynthetixUniswapLpRestake::init: reinitialize liquidity router address forbidden"
    );
    liquidityRouter = _liquidityRouter;
    slippage = _slippage;
    deadline = _deadline;
  }

  function deposit() external onlyOwner {
    IStaking _staking = staking; // gas optimisation
    IERC20 stakingToken = IERC20(_staking.stakingToken());
    uint256 balance = stakingToken.balanceOf(address(this));
    stakingToken.safeApprove(address(_staking), balance);
    _staking.stake(balance);
  }

  function refund() external onlyOwner {
    IStaking _staking = staking; // gas optimisation
    _staking.exit();

    address __owner = owner(); // gas optimisation
    IERC20 stakingToken = IERC20(_staking.stakingToken());
    stakingToken.transfer(__owner, stakingToken.balanceOf(address(this)));

    IERC20 rewardToken = IERC20(_staking.rewardsToken());
    rewardToken.transfer(__owner, rewardToken.balanceOf(address(this)));
  }

  function _swap(
    address[2] memory path,
    uint256[2] memory amount,
    uint256 _deadline
  ) internal returns (uint256) {
    if (path[0] == path[1]) return amount[0];

    address[] memory _path = new address[](2);
    _path[0] = path[0];
    _path[1] = path[1];

    return
      IUniswapV2Router02(liquidityRouter).swapExactTokensForTokens(
        amount[0],
        amount[1],
        _path,
        address(this),
        _deadline
      )[1];
  }

  function _addLiquidity(
    address[2] memory path,
    uint256[4] memory amount,
    uint256 _deadline
  ) internal {
    address _liquidityRouter = liquidityRouter; // gas optimisation
    IERC20(path[0]).safeApprove(_liquidityRouter, amount[0]);
    IERC20(path[1]).safeApprove(_liquidityRouter, amount[1]);
    IUniswapV2Router02(_liquidityRouter).addLiquidity(
      path[0],
      path[1],
      amount[0],
      amount[1],
      amount[2],
      amount[3],
      address(this),
      _deadline
    );
  }

  function run(
    uint256 gasFee,
    uint256 _deadline,
    uint256[2] memory _outMin
  ) external bill(gasFee, "BondappetitSynthetixLPRestake") {
    IStaking _staking = staking; // gas optimization
    require(_staking.earned(address(this)) > 0, "SynthetixUniswapLpRestake::run: no earned");

    _staking.getReward();
    address rewardToken = _staking.rewardsToken();
    uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));
    IERC20(rewardToken).safeApprove(liquidityRouter, rewardAmount);

    IUniswapV2Pair stakingToken = IUniswapV2Pair(_staking.stakingToken());
    address[2] memory tokens = [stakingToken.token0(), stakingToken.token1()];
    uint256[4] memory amount = [
      _swap([rewardToken, tokens[0]], [rewardAmount / 2, _outMin[0]], _deadline),
      _swap([rewardToken, tokens[1]], [rewardAmount - rewardAmount / 2, _outMin[1]], _deadline),
      0,
      0
    ];

    _addLiquidity([tokens[0], tokens[1]], amount, _deadline);
    uint256 stakingAmount = stakingToken.balanceOf(address(this));
    IERC20(stakingToken).safeApprove(address(_staking), stakingAmount);
    _staking.stake(stakingAmount);
  }
}
