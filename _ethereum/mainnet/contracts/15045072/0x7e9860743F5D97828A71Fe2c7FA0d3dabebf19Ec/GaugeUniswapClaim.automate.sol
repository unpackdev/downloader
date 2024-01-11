// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./Automate.sol";
import "./IRegistry.sol";
import "./IGauge.sol";
import "./IMinter.sol";
import "./IPlainPool.sol";
import "./IMetaPool.sol";
import "./IUniswapV2Router02.sol";
import "./ERC20Tools.sol";

// solhint-disable not-rely-on-time
contract GaugeUniswapClaim is Automate {
  using ERC20Tools for IERC20;

  IGauge public staking;

  address public liquidityRouter;

  address public swapToken;

  uint16 public slippage;

  uint16 public deadline;

  address public recipient;

  IERC20 internal _lpToken;

  address internal _pool;

  uint8 internal _swapTokenN;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _info) Automate(_info) {}

  function init(
    address _staking,
    address _liquidityRouter,
    address _swapToken,
    uint16 _slippage,
    uint16 _deadline,
    address _recipient
  ) external initializer {
    require(
      !_initialized || address(staking) == _staking,
      "GaugeUniswapRestake::init: reinitialize staking address forbidden"
    );
    staking = IGauge(_staking);
    require(
      !_initialized || liquidityRouter == _liquidityRouter,
      "GaugeUniswapRestake::init: reinitialize liquidity router address forbidden"
    );
    liquidityRouter = _liquidityRouter;
    swapToken = _swapToken;
    slippage = _slippage;
    deadline = _deadline;
    recipient = _recipient;

    if (!_initialized) {
      IRegistry registry = IRegistry(_registry());
      _lpToken = IERC20(staking.lp_token());
      _pool = registry.get_pool_from_lp_token(address(_lpToken));
      address[8] memory coins = registry.get_coins(_pool);
      uint256 nCoinsPool = registry.get_n_coins(_pool);

      for (; _swapTokenN <= nCoinsPool; _swapTokenN++) {
        require(_swapTokenN < nCoinsPool, "GaugeUniswapRestake::init: invalid swap token address");
        if (coins[_swapTokenN] == _swapToken) break;
      }
    }
  }

  function _registry() internal view returns (address) {
    return IStorage(info()).getAddress(keccak256("Curve:Contract:Registry"));
  }

  function deposit() external onlyOwner {
    IERC20 lpToken = _lpToken; // gas optimisation
    uint256 balance = lpToken.balanceOf(address(this));
    lpToken.safeApprove(address(staking), balance);
    staking.deposit(balance);
  }

  function refund() external onlyOwner {
    address __owner = owner(); // gas optimisation

    IGauge _staking = staking; // gas optimisation
    uint256 stakingBalance = _staking.balanceOf(address(this));
    if (stakingBalance > 0) {
      _staking.withdraw(stakingBalance);
    }
    uint256 lpBalance = _lpToken.balanceOf(address(this));
    if (lpBalance > 0) {
      _lpToken.transfer(__owner, lpBalance);
    }

    IMinter _minter = IMinter(staking.minter());
    _minter.mint(address(_staking));

    IERC20 rewardToken = IERC20(_staking.crv_token());
    uint256 rewardBalance = rewardToken.balanceOf(address(this));
    if (rewardBalance > 0) {
      rewardToken.transfer(__owner, rewardBalance);
    }
  }

  function run(
    uint256 gasFee,
    uint256 _deadline,
    uint256 swapOutMin
  ) external bill(gasFee, "CurveGaugeUniswapClaim") {
    IGauge _staking = staking; // gas optimization
    IERC20 _swapToken = IERC20(swapToken);

    IMinter _minter = IMinter(_staking.minter());
    _minter.mint(address(_staking));
    address rewardToken = _staking.crv_token();
    uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this));

    address[] memory _path = new address[](2);
    _path[0] = rewardToken;
    _path[1] = address(_swapToken);
    IERC20(rewardToken).safeApprove(liquidityRouter, rewardAmount);
    IUniswapV2Router02(liquidityRouter).swapExactTokensForTokens(
      rewardAmount,
      swapOutMin,
      _path,
      address(this),
      _deadline
    );

    _swapToken.transfer(recipient, _swapToken.balanceOf(address(this)));
  }
}
