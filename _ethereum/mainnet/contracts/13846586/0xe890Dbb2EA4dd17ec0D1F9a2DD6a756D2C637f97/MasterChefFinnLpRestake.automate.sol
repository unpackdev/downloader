// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./Automate.sol";
import "./IStorage.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IMasterChefFinnV2.sol";
import "./ERC20Tools.sol";

/**
 * @notice Use with LP token only.
 */
contract MasterChefFinnLpRestake is Automate {
  using ERC20Tools for IERC20;

  IMasterChefFinnV2 public staking;

  address public liquidityRouter;

  uint256 public pool;

  uint16 public slippage;

  uint16 public deadline;

  IERC20 public stakingToken;

  IERC20 public rewardToken;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _info) Automate(_info) {}

  function init(
    address _staking,
    address _liquidityRouter,
    uint256 _pool,
    uint16 _slippage,
    uint16 _deadline
  ) external initializer {
    require(
      !_initialized || address(staking) == _staking,
      "MasterChefFinnLpRestake::init: reinitialize staking address forbidden"
    );
    staking = IMasterChefFinnV2(_staking);
    require(
      !_initialized || liquidityRouter == _liquidityRouter,
      "MasterChefFinnLpRestake::init: reinitialize liquidity router address forbidden"
    );
    liquidityRouter = _liquidityRouter;
    require(!_initialized || pool == _pool, "MasterChefFinnLpRestake::init: reinitialize pool index forbidden");
    pool = _pool;
    slippage = _slippage;
    deadline = _deadline;

    if (!_initialized) {
      IMasterChefFinnV2.PoolInfo memory poolInfo = staking.poolInfo(pool);
      stakingToken = IERC20(poolInfo.lpToken);
      rewardToken = IERC20(staking.finn());
    }
  }

  function deposit() external onlyOwner {
    IERC20 _stakingToken = stakingToken; // gas optimisation
    uint256 balance = _stakingToken.balanceOf(address(this));
    _stakingToken.safeApprove(address(staking), balance);
    staking.deposit(pool, balance);
  }

  function refund() external onlyOwner {
    IMasterChefFinnV2 _staking = staking; // gas optimisation
    address __owner = owner(); // gas optimisation
    IMasterChefFinnV2.UserInfo memory userInfo = _staking.userInfo(pool, address(this));
    _staking.withdraw(pool, userInfo.amount);
    stakingToken.transfer(__owner, stakingToken.balanceOf(address(this)));
    rewardToken.transfer(__owner, rewardToken.balanceOf(address(this)));
  }

  function emergencyWithdraw() external onlyOwner {
    address __owner = owner(); // gas optimisation
    staking.emergencyWithdraw(pool);
    stakingToken.transfer(__owner, stakingToken.balanceOf(address(this)));
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
    uint256[2] memory amountIn,
    uint256[2] memory amountOutMin,
    uint256 _deadline
  ) internal {
    address _liquidityRouter = liquidityRouter; // gas optimisation
    IERC20(path[0]).safeApprove(_liquidityRouter, amountIn[0]);
    IERC20(path[1]).safeApprove(_liquidityRouter, amountIn[1]);
    IUniswapV2Router02(_liquidityRouter).addLiquidity(
      path[0],
      path[1],
      amountIn[0],
      amountIn[1],
      amountOutMin[0],
      amountOutMin[1],
      address(this),
      _deadline
    );
  }

  function run(
    uint256 gasFee,
    uint256 _deadline,
    uint256[2] memory _outMin
  ) external bill(gasFee, "MoonriverHuckleberryMasterChefFinnLPRestake") {
    IMasterChefFinnV2 _staking = staking; // gas optimization
    uint256 pendingFinn = _staking.pendingReward(pool, address(this));
    require(pendingFinn > 0, "MasterChefFinnLpRestake::run: no earned");

    _staking.deposit(pool, 0); // get all reward
    uint256 rewardAmount = rewardToken.balanceOf(address(this));
    rewardToken.safeApprove(liquidityRouter, rewardAmount);

    IUniswapV2Pair _stakingToken = IUniswapV2Pair(address(stakingToken));
    address[2] memory tokens = [_stakingToken.token0(), _stakingToken.token1()];
    uint256[2] memory amountIn = [
      _swap([address(rewardToken), tokens[0]], [rewardAmount / 2, _outMin[0]], _deadline),
      _swap([address(rewardToken), tokens[1]], [rewardAmount - rewardAmount / 2, _outMin[1]], _deadline)
    ];
    uint256[2] memory amountOutMin = [uint256(0), uint256(0)];

    _addLiquidity([tokens[0], tokens[1]], amountIn, amountOutMin, _deadline);
    uint256 stakingAmount = _stakingToken.balanceOf(address(this));
    stakingToken.safeApprove(address(_staking), stakingAmount);
    _staking.deposit(pool, stakingAmount);
  }
}
