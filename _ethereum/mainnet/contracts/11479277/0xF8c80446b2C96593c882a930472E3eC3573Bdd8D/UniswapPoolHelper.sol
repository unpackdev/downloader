// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./Console.sol";
import "./ERC20.sol";
import "./UniswapHelper.sol";

struct UniswapPoolHelperState {
  IUniswapV2Pair pair;
  address token0;
  address token1;
  uint256 min0;
  uint256 min1;
  uint256 allocated0;
  uint256 allocated1;
  uint256 liquidity;
  uint256 amount0;
  uint256 amount1;
  uint256 remaining0;
  uint256 remaining1;
  uint256 currBefore;
  uint256 currAfter;
  string path0;
  string path1;
  address from;
  address to;
}

library UniswapPoolHelper {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // TODO adjust MIN_AMOUNT
  uint256 public constant MIN_AMOUNT = 5;

  IUniswapV2Router02 public constant UNI_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  address constant public USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant public DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address constant public USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); 
  address public constant WBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

  IERC20 public constant IUSDC = IERC20(USDC);
  IERC20 public constant IUSDT = IERC20(USDT);
  IERC20 public constant IDAI = IERC20(DAI);

  uint256 public constant SLIPPAGE_BASE = 10000;

  function allocateState(uint256 amount0, uint256 amount1, IUniswapV2Pair pair, uint256 min0, uint256 min1) internal view returns (UniswapPoolHelperState memory state) {
    state = UniswapPoolHelperState(
      pair, 
      pair.token0(), 
      pair.token1(), 
      min0, 
      min1, 
      0, 
      0, 
      0, 
      amount0, 
      amount1,
      0,
      0,
      0,
      0,
      '',
      '',
      address(0),
      address(0)
    );
  }

  function allocateState(IUniswapV2Pair pair, uint256 min0, uint256 min1) internal view returns (UniswapPoolHelperState memory state) {
    state = allocateState(0, 0, pair, min0, min1);
  }

  function getPath(address token0, address token1) internal pure returns(address[] memory path) {
    path = new address[](2);
    path[0] = token0;
    path[1] = token1;
  }

  function safeTransferDeflationary(IERC20 token, uint256 amount, UniswapPoolHelperState memory state) internal returns (uint256 result) {
    state.currBefore = IERC20(token).balanceOf(address(this));
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    state.currAfter = IERC20(token).balanceOf(address(this));
    result = state.currAfter.sub(state.currBefore);
  }

  function safeTransferDeflationaryTo(address token, uint256 amount, UniswapPoolHelperState memory state) internal returns (uint256 result) {
    state.currBefore = IERC20(token).balanceOf(state.to);
    IERC20(token).safeTransfer(state.to, amount);
    state.currAfter = IERC20(token).balanceOf(state.to);
    result = state.currAfter.sub(state.currBefore);
  }

  function depositPair(uint256 amount0, uint256 amount1, IUniswapV2Pair pair, uint256 min0, uint256 min1) external returns (uint256) {
    require(amount0 > MIN_AMOUNT, '!amount0');
    require(amount1 > MIN_AMOUNT, '!amount1');

    UniswapPoolHelperState memory state = UniswapPoolHelper.allocateState(amount0, amount1, pair, min0, min1);

    state.amount0 = safeTransferDeflationary(IERC20(state.token0), state.amount0, state);
    state.amount1 = safeTransferDeflationary(IERC20(state.token1), state.amount1, state);
    addLiquidity(state);
    if (state.remaining0 > 0) {
      IERC20(state.token0).safeTransfer(msg.sender, state.remaining0);
    }
    if (state.remaining1 > 0) {
      IERC20(state.token1).safeTransfer(msg.sender, state.remaining1);
    }
    return state.liquidity;
  }

  function depositLPToken(IUniswapV2Pair pair, uint256 amount) external returns (uint256) {
    require(amount > MIN_AMOUNT, '!amount');
    UniswapPoolHelperState memory state = UniswapPoolHelper.allocateState(pair, 0, 0);
    return safeTransferDeflationary(IERC20(address(pair)), amount, state);
  }

  function addLiquidity(UniswapPoolHelperState memory state) internal {
    // debugBalances('addLiquidity', state);
    (state.allocated0, state.allocated1, state.liquidity) = UNI_ROUTER.addLiquidity(state.token0, state.token1, state.amount0, state.amount1, state.min0, state.min1, address(this), now.add(1800));
    state.remaining0 = state.amount0.sub(state.allocated0, '!remaining0');
    state.remaining1 = state.amount1.sub(state.allocated1, '!remaining1');
    // debugRemaining('addLiquidity', state);
  }

  function safeTransferReward(mapping (IERC20 => uint256) storage _rewardTotals, IERC20 reward, address dest, uint256 amount) internal returns(uint256) {
    uint256 remaining = _rewardTotals[reward];
    if (remaining < amount)
      amount = remaining;
    _rewardTotals[reward] = remaining.sub(amount);
    if (amount > 0) {
      uint256 bef = reward.balanceOf(dest);
      reward.safeTransfer(dest, amount);
      uint256 aft = reward.balanceOf(dest);
      amount = aft.sub(bef, '!reward');
    }
    return amount;
  }

  function claimToToken(
    UniswapHelper helper, 
    address to, 
    uint[] memory amounts,
    uint[] memory min, 
    mapping (address => mapping (IERC20 => uint256)) storage _owedRewards, 
    IERC20[] storage _rewards,
    mapping (IERC20 => uint256) storage _rewardTotals
  ) internal virtual {
    require(amounts.length == _rewards.length, 'amounts!=rewards');
    require(min.length == amounts.length, 'min!=rewards');
    mapping (IERC20 => uint256) storage owed = _owedRewards[msg.sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      uint256 amount = amounts[i];
      if (amount > 0) {
        uint256 rem = owed[token];
        require(amount <= rem, 'bad amount');
        owed[token] = rem.sub(amount);
        if (address(token) == to) {
          safeTransferReward(_rewardTotals, token, msg.sender, amount);
        } else {
          require(helper.pathExists(address(token), to), 'bad token');
          string memory path = Path.path(address(token), to);
          amount = safeTransferReward(_rewardTotals, token, address(helper), amount);
          if (amount > 0) {
            helper.swap(path, amount, min[i], msg.sender);
          }
        }
      }
    }
  }

  function owedRewards(
    mapping (address => mapping (IERC20 => uint256)) storage _owedRewards, 
    IERC20[] storage _rewards
  ) external view returns(uint256[] memory rewards) {
    rewards = new uint256[](_rewards.length);
    mapping (IERC20 => uint256) storage owed = _owedRewards[msg.sender];
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      rewards[i] = owed[token];
    }
  }

  function rewardTotals(
    mapping (IERC20 => uint256) storage _rewardTotals, 
    IERC20[] storage _rewards
  ) external view returns(uint256[] memory rewards) {
    rewards = new uint256[](_rewards.length);
    mapping (IERC20 => uint256) storage totals = _rewardTotals;
    for (uint256 i = 0; i < _rewards.length; i++) {
      IERC20 token = _rewards[i];
      rewards[i] = totals[token];
    }
  }

  function amountWithSlippage(uint256 amount, uint256 slippage) internal pure returns (uint256 out) {
    out = slippage == 0 ? 0 : amount.sub(amount.mul(slippage).div(SLIPPAGE_BASE));
  }

  function depositSingleSided(address help, address token, uint256 amountA, uint256 amountB, IUniswapV2Pair pair, uint256 minSwapB, uint256 slippageA, uint256 slippageB, uint256 slippageRemA, uint256 slippageRemB) external returns (uint256) {
    UniswapHelper helper = UniswapHelper(help);
    UniswapPoolHelperState memory state = UniswapPoolHelper.allocateState(pair, 0, 0);
    require(token == state.token0 || token == state.token1, 'invalid token');

    // Transfer tokens here
    amountB = safeTransferDeflationary(IERC20(token), amountB, state);
    amountA = safeTransferDeflationary(IERC20(token), amountA, state);
    // Transfer B to helper and swap
    state.to = help;
    amountB = safeTransferDeflationaryTo(token, amountB, state);
    state.from = token == state.token0 ? state.token0 : state.token1;
    state.to = state.from == state.token0 ? state.token1 : state.token0;
    state.path0 = Path.path(state.from, state.to);
    amountB = helper.swap(state.path0, amountB, minSwapB, address(this));

    state.amount0 = token == state.token0 ? amountA : amountB;
    state.amount1 = token == state.token0 ? amountB : amountA;

    state.min0 = amountWithSlippage(state.amount0, slippageA);
    state.min1 = amountWithSlippage(state.amount1, slippageB);

    addLiquidity(state);

    if (state.remaining0 > 0) {
      if (token == state.token1) {
        state.path0 = Path.path(state.token0, token);
        state.to = help;
        state.remaining0 = safeTransferDeflationaryTo(state.token0, state.remaining0, state); // IERC20(state.token0).safeTransfer(help, state.remaining0);
        state.min0 = helper.estimateOut(state.token0, token, state.remaining0);
        helper.swap(state.path0, state.remaining0, amountWithSlippage(state.min0, slippageRemA), msg.sender);
      } else {
        IERC20(state.token0).safeTransfer(msg.sender, state.remaining0);
      }
    }
    if (state.remaining1 > 0) {
      if (token == state.token0) {
        state.path1 = Path.path(state.token1, token);
        state.to = help;
        state.remaining1 = safeTransferDeflationaryTo(state.token1, state.remaining1, state);
        state.min1 = helper.estimateOut(state.token1, token, state.remaining1);
        helper.swap(state.path1, state.remaining1, amountWithSlippage(state.min1, slippageRemB), msg.sender);
      } else {
        IERC20(state.token1).safeTransfer(msg.sender, state.remaining1);
      }
    }

    return state.liquidity;
  }

  function depositFromToken(address help, address token, uint256 amountA, uint256 amountB, IUniswapV2Pair pair, uint256 minSwapA, uint256 minSwapB, uint256 slippageA, uint256 slippageB, uint256 slippageRemA, uint256 slippageRemB) external returns (uint256) {
    UniswapHelper helper = UniswapHelper(help);
    UniswapPoolHelperState memory state = UniswapPoolHelper.allocateState(pair, 0, 0);
    require(token != state.token0 && token != state.token1, 'use depositSingleSided');
    require(helper.pathExists(token, state.token0), 'bad token');
    require(helper.pathExists(token, state.token1), 'bad token');
    state.path0 = Path.path(token, state.token0);
    state.path1 = Path.path(token, state.token1);

    // This is inefficient but necessary for deflationary tokens
    amountA = safeTransferDeflationary(IERC20(token), amountA, state);
    amountB = safeTransferDeflationary(IERC20(token), amountB, state);
    state.to = help;
    amountA = safeTransferDeflationaryTo(token, amountA, state);
    amountB = safeTransferDeflationaryTo(token, amountB, state);

    state.amount0 = helper.swap(state.path0, amountA, minSwapA, address(this));
    state.amount1 = helper.swap(state.path1, amountB, minSwapB, address(this));
    state.min0 = amountWithSlippage(state.amount0, slippageA);
    state.min1 = amountWithSlippage(state.amount1, slippageB);

    addLiquidity(state);

    if (state.remaining0 > 0) {
      state.path0 = Path.path(state.token0, token);
      state.to = help;
      state.remaining0 = safeTransferDeflationaryTo(state.token0, state.remaining0, state); // IERC20(state.token0).safeTransfer(help, state.remaining0);
      state.min0 = helper.estimateOut(state.token0, token, state.remaining0);
      helper.swap(state.path0, state.remaining0, amountWithSlippage(state.min0, slippageRemA), msg.sender);
    }
    if (state.remaining1 > 0) {
      state.path1 = Path.path(state.token1, token);
      state.to = help;
      state.remaining1 = safeTransferDeflationaryTo(state.token1, state.remaining1, state);
      state.min1 = helper.estimateOut(state.token1, token, state.remaining1);
      helper.swap(state.path1, state.remaining1, amountWithSlippage(state.min1, slippageRemB), msg.sender);
    }

    return state.liquidity;
  }

  function debugAmounts(string memory method, UniswapPoolHelperState memory state) internal {
    Console.log(method, ' token0 amount ', ERC20(state.token0).symbol(), state.amount0);
    Console.log(method, ' token1 amount ', ERC20(state.token1).symbol(), state.amount1);
  }

  function debugBalances(string memory method, UniswapPoolHelperState memory state) internal {
    Console.log(method, ' token0 balance ', ERC20(state.token0).symbol(), IERC20(state.token0).balanceOf(address(this)));
    Console.log(method, ' token1 balance ', ERC20(state.token1).symbol(), IERC20(state.token1).balanceOf(address(this)));
  }

  function debugRemaining(string memory method, UniswapPoolHelperState memory state) internal {
    Console.log(method, ' token0 remaining ', ERC20(state.token0).symbol(), state.remaining0);
    Console.log(method, ' token1 remaining ', ERC20(state.token1).symbol(), state.remaining1);
  }

  function debugSwap(address token, uint256 amount, address tokenOut, uint256 out) internal {
    Console.log('swap in ', ERC20(token).name(), amount);
    Console.log('swap out ', ERC20(tokenOut).name(), out);
  }

}
