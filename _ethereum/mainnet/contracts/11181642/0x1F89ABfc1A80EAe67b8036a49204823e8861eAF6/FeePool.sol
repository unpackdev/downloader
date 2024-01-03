// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

import "./Math.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./IJusDeFi.sol";
import "./IStakingPool.sol";

contract FeePool {
  address private immutable _jusdefi;

  address private immutable _uniswapRouter;
  address private immutable _uniswapPair;

  address public immutable _jdfiStakingPool;
  address public immutable _univ2StakingPool;

  // fee specified in basis points
  uint public _fee; // initialized at 0; not set until #liquidityEventClose
  uint private constant FEE_BASE = 1000;
  uint private constant BP_DIVISOR = 10000;

  // allow slippage of 0.6%
  uint private constant BUYBACK_SLIPPAGE = 60;

  uint private constant UNIV2_STAKING_MULTIPLIER = 3;

  uint private immutable _initialUniTotalSupply;

  uint public _votesIncrease;
  uint public _votesDecrease;

  uint private _lastBuybackAt;
  uint private _lastRebaseAt;

  constructor (
    address jdfiStakingPool,
    address univ2StakingPool,
    address uniswapRouter,
    address uniswapPair
  ) {
    _jusdefi = msg.sender;
    _jdfiStakingPool = jdfiStakingPool;
    _univ2StakingPool = univ2StakingPool;
    _uniswapRouter = uniswapRouter;
    _uniswapPair = uniswapPair;

    // approve router to handle UNI-V2 for buybacks
    IUniswapV2Pair(uniswapPair).approve(uniswapRouter, type(uint).max);

    _initialUniTotalSupply = IUniswapV2Pair(uniswapPair).mint(address(this)) + IUniswapV2Pair(uniswapPair).MINIMUM_LIQUIDITY();
    _fee = FEE_BASE;
  }

  receive () external payable {
    require(msg.sender == _uniswapRouter || msg.sender == _jdfiStakingPool, 'JusDeFi: invalid ETH deposit');
  }

  /**
   * @notice calculate quantity of JDFI to withhold (burned and as rewards) on unstake
   * @param amount quantity untsaked
   * @return unt quantity withheld
   */
  function calculateWithholding (uint amount) external view returns (uint) {
    return amount * _fee / BP_DIVISOR;
  }

  /**
   * @notice vote for weekly fee changes by sending ETH
   * @param increase whether vote is to increase or decrease the fee
   */
  function vote (bool increase) external payable {
    if (increase) {
      _votesIncrease += msg.value;
    } else {
      _votesDecrease += msg.value;
    }
  }

  /**
   * @notice withdraw Uniswap liquidity in excess of initial amount, purchase and burn JDFI
   */
  function buyback () external {
    require(block.timestamp / (1 days) % 7 == 1, 'JusDeFi: buyback must take place on Friday (UTC)');
    require(block.timestamp - _lastBuybackAt > 1 days, 'JusDeFi: buyback already called this week');
    _lastBuybackAt = block.timestamp;

    address[] memory path = new address[](2);
    path[0] = IUniswapV2Router02(_uniswapRouter).WETH();
    path[1] = _jusdefi;

    // check output to fail fast if price has changed beyond allowed limits

    uint[] memory outputs = IUniswapV2Router02(_uniswapRouter).getAmountsOut(
      1e9,
      path
    );

    uint requiredOutput = IJusDeFi(_jusdefi).consult(1e9);

    require(outputs[1] * (BP_DIVISOR + BUYBACK_SLIPPAGE) / BP_DIVISOR  >= requiredOutput, 'JusDeFi: buyback price slippage too high');

    uint initialBalance = IJusDeFi(_jusdefi).balanceOf(address(this));

    // remove liquidity in excess of original amount

    uint initialUniTotalSupply = _initialUniTotalSupply;
    uint uniTotalSupply = IUniswapV2Pair(_uniswapPair).totalSupply();

    if (uniTotalSupply > initialUniTotalSupply) {
      uint delta = Math.min(
        IUniswapV2Pair(_uniswapPair).balanceOf(address(this)),
        uniTotalSupply - initialUniTotalSupply
      );

      if (delta > 0) {
        // minimum output not relevant due to earlier check
        IUniswapV2Router02(_uniswapRouter).removeLiquidityETH(
          _jusdefi,
          delta,
          0,
          0,
          address(this),
          block.timestamp
        );
      }
    }

    // buyback JDFI using ETH from withdrawn liquidity and fee votes

    if (address(this).balance > 0) {
      // minimum output not relevant due to earlier check
      IUniswapV2Router02(_uniswapRouter).swapExactETHForTokens{
        value: address(this).balance
      }(
        0,
        path,
        address(this),
        block.timestamp
      );
    }

    IJusDeFi(_jusdefi).burn(IJusDeFi(_jusdefi).balanceOf(address(this)) - initialBalance);
  }

  /**
   * @notice distribute collected fees to staking pools
   */
  function rebase () external {
    require(block.timestamp / (1 days) % 7 == 3, 'JusDeFi: rebase must take place on Sunday (UTC)');
    require(block.timestamp - _lastRebaseAt > 1 days, 'JusDeFi: rebase already called this week');
    _lastRebaseAt = block.timestamp;

    // skim to prevent manipulation of JDFI reserve
    IUniswapV2Pair(_uniswapPair).skim(address(this));
    uint rewards = IJusDeFi(_jusdefi).balanceOf(address(this));

    uint jdfiStakingPoolStaked = IERC20(_jdfiStakingPool).totalSupply();
    uint univ2StakingPoolStaked = IJusDeFi(_jusdefi).balanceOf(_uniswapPair) * IERC20(_univ2StakingPool).totalSupply() / IUniswapV2Pair(_uniswapPair).totalSupply();

    uint weight = jdfiStakingPoolStaked + univ2StakingPoolStaked * UNIV2_STAKING_MULTIPLIER;

    // if weight is zero, staked amounts are also zero, avoiding zero-division error

    if (jdfiStakingPoolStaked > 0) {
      IStakingPool(_jdfiStakingPool).distributeRewards(
        rewards * jdfiStakingPoolStaked / weight
      );
    }

    if (univ2StakingPoolStaked > 0) {
      IStakingPool(_univ2StakingPool).distributeRewards(
        rewards * univ2StakingPoolStaked * UNIV2_STAKING_MULTIPLIER / weight
      );
    }

    // set fee for the next week

    uint increase = _votesIncrease;
    uint decrease = _votesDecrease;

    if (increase > decrease) {
      _fee = FEE_BASE + _sigmoid(increase - decrease);
    } else if (increase < decrease) {
      _fee = FEE_BASE - _sigmoid(decrease - increase);
    } else {
      _fee = FEE_BASE;
    }

    _votesIncrease = 0;
    _votesDecrease = 0;
  }

  /**
   * @notice calculate fee offset based on net votes
   * @dev input is a uint, therefore sigmoid is only implemented for positive values
   * @return uint fee offset from FEE_BASE
   */
  function _sigmoid (uint net) private pure returns (uint) {
    return FEE_BASE * net / (3 ether + net);
  }
}
