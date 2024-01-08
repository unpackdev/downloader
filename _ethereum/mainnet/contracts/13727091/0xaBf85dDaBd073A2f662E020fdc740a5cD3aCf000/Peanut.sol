//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./INonfungiblePositionManager.sol";
import "./ISwapRouter.sol";
import "./TransferHelper.sol";
import "./LiquidityAmounts.sol";
import "./IWETH9.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

import "./Exchanger.sol";

contract Peanut is ERC20, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;
  uint256 private _currentPositionId;

  bool public paused = false;
  uint256 public currentVaultFee = 0;
  uint256 public currentManagementFeePercent;

  uint256 public maxPoolLimitInToken0;
  uint256 public maxPoolLimitInToken1;
  uint256 public percentOfAmountMin;

  address public vaultAddress;
  address public managerAddress;
  address public exchanger;

  uint256 private constant hundredPercent = 1000000;
  uint256 private constant MAX_BASIS_POINTS = 10**18;
  INonfungiblePositionManager public constant uniswapV3PositionsNFT =
    INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  address public constant uniswapV3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  int24 public immutable tickSpacing;
  uint24 public immutable protocolFee;
  uint256 public immutable maxVaultFeePercent;
  uint256 public immutable maxManagementFeePercent;

  address public immutable uniswapV3Pool;
  address public immutable token0;
  address public immutable token1;
  uint256 private immutable decimalsToken0;
  uint256 private immutable decimalsToken1;

  struct Balances {
    uint256 amount0;
    uint256 amount1;
  }

  struct Ticks {
    int24 tickLower;
    int24 tickUpper;
  }

  /// @notice Modifier for check msg.sender for permission functions
  modifier isAllowedCaller() {
    require(msg.sender == owner() || msg.sender == managerAddress);
    _;
  }

  modifier isPaused() {
    require(!paused);
    _;
  }

  receive() external payable {
    require(msg.sender == WETH || msg.sender == address(uniswapV3PositionsNFT));
  }

  constructor(
    address _uniswapV3Pool,
    address _owner,
    address _manager,
    address _exchanger,
    uint256 _currentManagementFeePercent,
    uint256 _maxVaultFee,
    uint256 _maxManagementFeePercent,
    uint256 _maxPoolLimitInToken0,
    uint256 _maxPoolLimitInToken1,
    uint256 _percentOfAmountMin
  ) ERC20('Smart LP', 'SLP') {
    uniswapV3Pool = _uniswapV3Pool;
    exchanger = _exchanger;
    managerAddress = _manager;
    currentManagementFeePercent = _currentManagementFeePercent;
    maxVaultFeePercent = _maxVaultFee;
    maxManagementFeePercent = _maxManagementFeePercent;
    maxPoolLimitInToken0 = _maxPoolLimitInToken0;
    maxPoolLimitInToken1 = _maxPoolLimitInToken1;
    percentOfAmountMin = _percentOfAmountMin;
    transferOwnership(_owner);
    vaultAddress = owner();

    IUniswapV3Pool UniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);
    token0 = UniswapV3Pool.token0();
    token1 = UniswapV3Pool.token1();
    protocolFee = UniswapV3Pool.fee();
    tickSpacing = UniswapV3Pool.tickSpacing();

    decimalsToken0 = 10**(ERC20(UniswapV3Pool.token0()).decimals());
    decimalsToken1 = 10**(ERC20(UniswapV3Pool.token1()).decimals());
  }

  //Events

  event PositionChanged(
    address addressSender,
    uint256 newPositionId,
    uint160 sqrtPriceLowerX96,
    uint160 sqrtPriceUpperX96
  );
  event LiquidityAdded(address addressSender, uint128 liquidity, uint256 amount0, uint256 amount1);
  event LiquidityRemoved(
    address addressSender,
    uint128 liquidity,
    uint256 amount0,
    uint256 amount1
  );
  event Claimed(
    address addressSender,
    uint256 amountLP,
    uint256 amount0Claimed,
    uint256 amount1Claimed
  );
  event FeeCollected(address addressSender, uint256 amount0Collected, uint256 amount1Collected);

  //Functions

  function getCurrentSqrtPrice() public view returns (uint160 sqrtPriceX96) {
    (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
  }

  function getCurrentPositionId() public view returns (uint256) {
    return _currentPositionId;
  }

  function getTickForSqrtPrice(uint160 sqrtPriceX96) public view returns (int24) {
    int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    int24 tickCorrection = tick % int24(tickSpacing);
    return tick - tickCorrection;
  }

  function getUserShare(address account) public view returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return balanceOf(account).mul(hundredPercent).div(totalSupply());
  }

  function getCurrentAmountsForPosition() public view returns (uint256 amount0, uint256 amount1) {
    require(_currentPositionId > 0);
    (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = uniswapV3PositionsNFT
    .positions(_currentPositionId);
    (uint160 sqrtPriceCurrentX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
    uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(tickLower);
    uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
      sqrtPriceCurrentX96,
      sqrtPriceLowerX96,
      sqrtPriceUpperX96,
      liquidity
    );
  }

  function getBalances() public view returns (uint256 amount0, uint256 amount1) {
    return _getBalances(0);
  }

  function setPercentOfAmountMin(uint256 _percentOfAmountMin) public onlyOwner {
    percentOfAmountMin = _percentOfAmountMin;
  }

  function setCurrentManagementFeePercent(uint256 _currentManagementFeePercent) public onlyOwner {
    require(_currentManagementFeePercent <= maxManagementFeePercent);
    currentManagementFeePercent = _currentManagementFeePercent;
  }

  function setMaxPoolLimit(uint256 _maxPoolLimitInToken0, uint256 _maxPoolLimitInToken1)
    public
    onlyOwner
  {
    maxPoolLimitInToken0 = _maxPoolLimitInToken0;
    maxPoolLimitInToken1 = _maxPoolLimitInToken1;
  }

  function setExchangerStrategy(address _address) public onlyOwner {
    exchanger = _address;
  }

  function setVault(address _address) public onlyOwner {
    vaultAddress = _address;
  }

  function setCurrentVaultFee(uint256 _vaultFee) public onlyOwner {
    require(_vaultFee <= maxVaultFeePercent);
    currentVaultFee = _vaultFee;
  }

  function setManager(address _address) external onlyOwner {
    managerAddress = _address;
  }

  function setPaused(bool _paused) public onlyOwner {
    paused = _paused;
  }

  function createPositionForGivenSqrtPrices(
    uint160 sqrtPriceLowerX96,
    uint160 sqrtPriceUpperX96,
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0OutMin,
    uint256 amount1OutMin
  ) public payable onlyOwner isPaused {
    require(_currentPositionId == 0);

    // Check for token allowance
    _checkAllowance(token0, amount0Desired);
    _checkAllowance(token1, amount1Desired);

    // Receive tokens
    _transferTokenFrom(token0, msg.sender, amount0Desired);
    _transferTokenFrom(token1, msg.sender, amount1Desired);

    // Create position in uniswap
    uint128 liquidity = _createPositionForGivenSqrtPrices(
      sqrtPriceLowerX96,
      sqrtPriceUpperX96,
      amount0OutMin,
      amount1OutMin
    );

    // Refund tokens from uniswap
    _refundFromUniswap();

    // Mint tokens to msg.sender
    _mint(msg.sender, liquidity);

    // Return tokens to caller
    _refund(Balances(0, 0));
  }

  function changePositionForGivenSqrtPrices(
    uint160 sqrtPriceLowerX96,
    uint160 sqrtPriceUpperX96,
    uint256 amount0OutMin,
    uint256 amount1OutMin
  ) public isAllowedCaller isPaused {
    require(_currentPositionId > 0);
    (, , , , , , , uint128 liquidity, , , , ) = uniswapV3PositionsNFT.positions(_currentPositionId);
    _removeLiquidity(liquidity);
    _createPositionForGivenSqrtPrices(
      sqrtPriceLowerX96,
      sqrtPriceUpperX96,
      amount0OutMin,
      amount1OutMin
    );
    // Refund tokens from uniswap
    _refundFromUniswap();
    emit PositionChanged(msg.sender, _currentPositionId, sqrtPriceLowerX96, sqrtPriceUpperX96);
  }

  function addLiquidity(
    uint256 amount0,
    uint256 amount1,
    uint256 amount0OutMin,
    uint256 amount1OutMin
  ) public payable isPaused {
    require(_currentPositionId > 0);

    (uint256 amount0CurrentLiq, uint256 amount1CurrentLiq) = getCurrentAmountsForPosition();
    require(
      amount0CurrentLiq.add(amount0) <= maxPoolLimitInToken0 &&
        amount1CurrentLiq.add(amount1) <= maxPoolLimitInToken1
    );

    _checkAllowance(token0, amount0);
    _checkAllowance(token1, amount1);

    // Collect tokens from position to the contract.
    // Get balance of contract without user tokens, but with collected ones.
    // Swap them in order to have a right proportion.
    // Increase liquidity.
    _collectFeeAndReinvest(amount0OutMin, amount1OutMin, msg.value);

    // Contract balance of tokens after collecting fee and increasing liquidity (without user eth amount).
    (uint256 contractAmount0, uint256 contractAmount1) = _getBalances(msg.value);

    // Receive tokens from user.
    _transferTokenFrom(token0, msg.sender, amount0);
    _transferTokenFrom(token1, msg.sender, amount1);

    (, , , , , , , uint128 prevLiquidity, , , , ) = uniswapV3PositionsNFT.positions(
      _currentPositionId
    );

    // Add user tokens to position liquidity.
    uint128 liquidity = _addUserLiquidity(
      Balances(contractAmount0, contractAmount1),
      amount0,
      amount1
    );

    uint256 amount = _calculateAmountForLiquidity(prevLiquidity, liquidity);

    _refundFromUniswap();

    _mint(msg.sender, amount);

    _refund(Balances(contractAmount0, contractAmount1));

    emit LiquidityAdded(msg.sender, liquidity, amount0, amount1);
  }

  function collectFee(uint256 amount0OutMin, uint256 amount1OutMin)
    public
    isAllowedCaller
    isPaused
  {
    _collectFeeAndReinvest(amount0OutMin, amount1OutMin, 0);
  }

  function _collectFee() private returns (bool) {
    (uint256 amount0Collected, uint256 amount1Collected) = uniswapV3PositionsNFT.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _currentPositionId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );

    if (amount0Collected > 0 || amount1Collected > 0) {
      _withdraw(_isWETH(token0) ? amount0Collected : amount1Collected);

      _transferManagementFee(amount0Collected, amount1Collected);

      emit FeeCollected(msg.sender, amount0Collected, amount1Collected);

      return true;
    }

    return false;
  }

  function _collectFeeAndReinvest(
    uint256 amount0OutMin,
    uint256 amount1OutMin,
    uint256 userMsgValue
  ) private isPaused {
    require(_currentPositionId > 0);

    bool isCollected = _collectFee();
    if (!isCollected) {
      return;
    }

    // Contract balance of tokens after collect and before swap (without user amount of eth).
    (uint256 contractAmount0, uint256 contractAmount1) = _getBalances(userMsgValue);

    (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = uniswapV3PositionsNFT.positions(
      _currentPositionId
    );
    (, , bool shouldIncreaseLiquidity) = _swapTokensStrategy(
      Balances(contractAmount0, contractAmount1),
      Ticks(tickLower, tickUpper),
      amount0OutMin,
      amount1OutMin
    );

    if (!shouldIncreaseLiquidity) {
      return;
    }

    // Contract balance of tokens after swap (without user amount of eth).
    (contractAmount0, contractAmount1) = _getBalances(userMsgValue);

    uint256 valueETH = 0;
    if (_isWETH(token0) || _isWETH(token1)) {
      valueETH = _isWETH(token0) ? contractAmount0 : contractAmount1;
    }

    _increaseAllowance(token0, address(uniswapV3PositionsNFT), contractAmount0);
    _increaseAllowance(token1, address(uniswapV3PositionsNFT), contractAmount1);
    uniswapV3PositionsNFT.increaseLiquidity{ value: valueETH }(
      INonfungiblePositionManager.IncreaseLiquidityParams({
        tokenId: _currentPositionId,
        amount0Desired: contractAmount0,
        amount1Desired: contractAmount1,
        amount0Min: _calculateAmountMin(contractAmount0),
        amount1Min: _calculateAmountMin(contractAmount1),
        deadline: 10000000000
      })
    );

    // Refund tokens from uniswap.
    _refundFromUniswap();
  }

  function claim(
    uint256 amount,
    uint256 amount0OutMin,
    uint256 amount1OutMin
  ) public isPaused {
    (uint256 amount0Decreased, uint256 amount1Decreased) = _claim(
      amount,
      amount0OutMin,
      amount1OutMin
    );
    _transferToken(token0, msg.sender, amount0Decreased);
    _transferToken(token1, msg.sender, amount1Decreased);
    emit Claimed(msg.sender, amount, amount0Decreased, amount1Decreased);
  }

  function claimToken(
    address token,
    uint256 amount,
    uint256 amount0OutMin,
    uint256 amount1OutMin
  ) public isPaused {
    require(token == token0 || token == token1);
    (uint256 amount0WithoutFee, uint256 amount1WithoutFee) = _claim(
      amount,
      amount0OutMin,
      amount1OutMin
    );
    uint256 amountForToken;
    (uint256 amountOutToken, address secondToken, uint256 amountDecreased) = token == token0
      ? (amount0WithoutFee, token1, amount1WithoutFee)
      : (amount1WithoutFee, token0, amount0WithoutFee);
    if (amountDecreased > 0) {
      (amountForToken) = _swapExact(secondToken, amountDecreased, 0);
    }
    _transferToken(token, msg.sender, amountOutToken.add(amountForToken));

    emit Claimed(msg.sender, amount, amount0WithoutFee, amount1WithoutFee);
  }

  // Private functions

  function _isWETH(address token) private pure returns (bool) {
    return token == WETH;
  }

  function _checkAllowance(address token, uint256 amount) private view {
    if (_isWETH(token)) {
      require(amount <= msg.value);
      return;
    }
    require(ERC20(token).allowance(msg.sender, address(this)) >= amount);
  }

  function _transferToken(
    address token,
    address receiver,
    uint256 amount
  ) private {
    if (_isWETH(token)) {
      TransferHelper.safeTransferETH(receiver, amount);
      return;
    }
    TransferHelper.safeTransfer(token, receiver, amount);
  }

  function _createPositionForGivenSqrtPrices(
    uint160 sqrtPriceLowerX96,
    uint160 sqrtPriceUpperX96,
    uint256 amount0OutMin,
    uint256 amount1OutMin
  ) private returns (uint128) {
    int24 tickLower = getTickForSqrtPrice(sqrtPriceLowerX96);
    int24 tickUpper = getTickForSqrtPrice(sqrtPriceUpperX96);

    (uint256 amount0ForSwap, uint256 amount1ForSwap) = getBalances();

    (uint256 amount0, uint256 amount1, ) = _swapTokensStrategy(
      Balances(amount0ForSwap, amount1ForSwap),
      Ticks(tickLower, tickUpper),
      amount0OutMin,
      amount1OutMin
    );

    require(tickUpper > tickLower);

    _increaseAllowance(token0, address(uniswapV3PositionsNFT), amount0);
    _increaseAllowance(token1, address(uniswapV3PositionsNFT), amount1);

    uint256 valueETH = 0;
    if (_isWETH(token0) || _isWETH(token1)) {
      valueETH = _isWETH(token0) ? amount0 : amount1;
    }

    (uint256 tokenId, uint128 liquidity, , ) = uniswapV3PositionsNFT.mint{ value: valueETH }(
      INonfungiblePositionManager.MintParams({
        token0: token0,
        token1: token1,
        fee: protocolFee,
        tickLower: tickLower,
        tickUpper: tickUpper,
        amount0Desired: amount0,
        amount1Desired: amount1,
        amount0Min: _calculateAmountMin(amount0),
        amount1Min: _calculateAmountMin(amount1),
        recipient: address(this),
        deadline: 10000000000
      })
    );
    _currentPositionId = tokenId;
    return liquidity;
  }

  function _increaseAllowance(
    address token,
    address receiver,
    uint256 amount
  ) private {
    if (_isWETH(token)) {
      return;
    }
    uint256 allowed = ERC20(token).allowance(address(this), receiver);
    if (allowed != 0) {
      ERC20(token).safeDecreaseAllowance(receiver, allowed);
    }
    ERC20(token).safeIncreaseAllowance(receiver, amount);
  }

  function _swapTokensStrategy(
    Balances memory balances,
    Ticks memory ticks,
    uint256 amount0OutMin,
    uint256 amount1OutMin
  )
    internal
    returns (
      uint256 amount0,
      uint256 amount1,
      bool isRebalanced
    )
  {
    (
      uint256 amount0ToSwap,
      uint256 amount1ToSwap,
      uint256 amount0AfterSwap,
      uint256 amount1AfterSwap,

    ) = Exchanger(exchanger).rebalance(
      ticks.tickLower,
      ticks.tickUpper,
      balances.amount0,
      balances.amount1
    );
    if (amount0AfterSwap == 0 || amount1AfterSwap == 0) {
      isRebalanced = false;
      return (0, 0, isRebalanced);
    }
    isRebalanced = true;
    if (amount0ToSwap != 0) {
      _swapExact(token0, amount0ToSwap, amount1OutMin);
    } else if (amount1ToSwap != 0) {
      _swapExact(token1, amount1ToSwap, amount0OutMin);
    }

    (amount0, amount1) = getBalances();
  }

  function _getBalances(uint256 transferredAmount)
    private
    view
    returns (uint256 amount0, uint256 amount1)
  {
    amount0 = _isWETH(token0)
      ? address(this).balance.sub(transferredAmount)
      : ERC20(token0).balanceOf(address(this));
    amount1 = _isWETH(token1)
      ? address(this).balance.sub(transferredAmount)
      : ERC20(token1).balanceOf(address(this));
  }

  function _swapExact(
    address token,
    uint256 amount,
    uint256 amountOutMin
  ) private returns (uint256 amountOut) {
    return
      _isWETH(token)
        ? _swapExactETHToTokens(amount, amountOutMin)
        : _swapExactTokens(token, amount, amountOutMin);
  }

  function _swapExactTokens(
    address tokenIn,
    uint256 amountIn,
    uint256 amountOutMin
  ) private returns (uint256 amountOut) {
    _increaseAllowance(tokenIn, uniswapV3Router, amountIn);
    address tokenOut = tokenIn == token0 ? token1 : token0;
    (amountOut) = ISwapRouter(uniswapV3Router).exactInputSingle(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: tokenIn,
        tokenOut: tokenOut,
        fee: protocolFee,
        recipient: address(this),
        deadline: 10000000000,
        amountIn: amountIn,
        amountOutMinimum: amountOutMin,
        sqrtPriceLimitX96: 0
      })
    );
    if (_isWETH(tokenOut)) {
      IWETH9(tokenOut).withdraw(IWETH9(tokenOut).balanceOf(address(this)));
    }
  }

  function _swapExactETHToTokens(uint256 amountIn, uint256 amountOutMin)
    private
    returns (uint256 amountOut)
  {
    require(_isWETH(token0) || _isWETH(token1));
    (address tokenInWETH, address tokenOutNotWETH) = _isWETH(token0)
      ? (token0, token1)
      : (token1, token0);

    (amountOut) = ISwapRouter(uniswapV3Router).exactInputSingle{ value: amountIn }(
      ISwapRouter.ExactInputSingleParams({
        tokenIn: tokenInWETH,
        tokenOut: tokenOutNotWETH,
        fee: protocolFee,
        recipient: address(this),
        deadline: 10000000000,
        amountIn: amountIn,
        amountOutMinimum: amountOutMin,
        sqrtPriceLimitX96: 0
      })
    );
  }

  function _refund(Balances memory startBalances) private {
    (uint256 amount0, uint256 amount1) = getBalances();
    _refundETHOrToken(amount0, startBalances.amount0, token0);
    _refundETHOrToken(amount1, startBalances.amount1, token1);
  }

  function _refundETHOrToken(
    uint256 balance,
    uint256 startBalance,
    address token
  ) private {
    if (balance > startBalance) {
      _isWETH(token)
        ? TransferHelper.safeTransferETH(msg.sender, balance - startBalance)
        : TransferHelper.safeTransfer(token, msg.sender, balance - startBalance);
    }
  }

  function _removeLiquidity(uint128 liquidity) private returns (uint256 amount0, uint256 amount1) {
    (uint256 amount0CurrentLiq, uint256 amount1CurrentLiq) = getCurrentAmountsForPosition();
    (uint256 amount0Decreased, uint256 amount1Decreased) = uniswapV3PositionsNFT.decreaseLiquidity(
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: _currentPositionId,
        liquidity: liquidity,
        amount0Min: _calculateAmountMin(amount0CurrentLiq),
        amount1Min: _calculateAmountMin(amount1CurrentLiq),
        deadline: 10000000000
      })
    );
    (uint256 amount0Collected, uint256 amount1Collected) = uniswapV3PositionsNFT.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _currentPositionId,
        recipient: address(this),
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      })
    );

    uint256 amount0Fee = amount0Collected.sub(amount0Decreased);
    uint256 amount1Fee = amount1Collected.sub(amount1Decreased);

    emit FeeCollected(msg.sender, amount0Fee, amount1Fee);

    _withdraw(_isWETH(token0) ? amount0Collected : amount1Collected);

    (uint256 amount0FeeForVault, uint256 amount1FeeForVault) = _transferManagementFee(
      amount0Fee,
      amount1Fee
    );

    emit LiquidityRemoved(msg.sender, liquidity, amount0Collected, amount1Collected);

    return (amount0Collected.sub(amount0FeeForVault), amount1Collected.sub(amount1FeeForVault));
  }

  function _withdraw(uint256 amount) private {
    if (!(_isWETH(token0) || _isWETH(token1))) {
      return;
    }
    IWETH9(WETH).withdraw(amount);
  }

  function _addUserLiquidity(
    Balances memory contractBalance,
    uint256 amount0,
    uint256 amount1
  ) private returns (uint128 liquidity) {
    (, , , , , int24 tickLower, int24 tickUpper, , , , , ) = uniswapV3PositionsNFT.positions(
      _currentPositionId
    );

    (uint256 contractAmount0AfterSwap, uint256 contractAmount1AfterSwap, ) = _swapTokensStrategy(
      Balances(amount0, amount1),
      Ticks(tickLower, tickUpper),
      0,
      0
    );

    uint256 userAmount0 = contractAmount0AfterSwap.sub(contractBalance.amount0);
    uint256 userAmount1 = contractAmount1AfterSwap.sub(contractBalance.amount1);

    uint256 valueETH = 0;
    if (_isWETH(token0) || _isWETH(token1)) {
      valueETH = _isWETH(token0) ? userAmount0 : userAmount1;
    }

    _increaseAllowance(token0, address(uniswapV3PositionsNFT), userAmount0);
    _increaseAllowance(token1, address(uniswapV3PositionsNFT), userAmount1);
    (liquidity, , ) = uniswapV3PositionsNFT.increaseLiquidity{ value: valueETH }(
      INonfungiblePositionManager.IncreaseLiquidityParams({
        tokenId: _currentPositionId,
        amount0Desired: userAmount0,
        amount1Desired: userAmount1,
        amount0Min: _calculateAmountMin(userAmount0),
        amount1Min: _calculateAmountMin(userAmount1),
        deadline: 10000000000
      })
    );
  }

  function _transferManagementFee(uint256 amount0, uint256 amount1)
    private
    returns (uint256 amount0FeeForVault, uint256 amount1FeeForVault)
  {
    amount0FeeForVault = 0;
    amount1FeeForVault = 0;

    if (amount0 > 0) {
      amount0FeeForVault = FullMath.mulDiv(amount0, currentManagementFeePercent, hundredPercent);

      _transferToken(token0, vaultAddress, amount0FeeForVault);
    }

    if (amount1 > 0) {
      amount1FeeForVault = FullMath.mulDiv(amount1, currentManagementFeePercent, hundredPercent);

      _transferToken(token1, vaultAddress, amount1FeeForVault);
    }
  }

  function _transferTokenFrom(
    address token,
    address sender,
    uint256 amount
  ) private {
    if (_isWETH(token)) {
      return;
    }
    ERC20(token).safeTransferFrom(sender, address(this), amount);
  }

  function _claim(
    uint256 amount,
    uint256 amount0OutMin,
    uint256 amount1OutMin
  ) private returns (uint256 amount0Decreased, uint256 amount1Decreased) {
    require(_currentPositionId > 0);
    require(amount <= balanceOf(msg.sender));

    (, , , , , , , uint128 newLiquidity, , , , ) = uniswapV3PositionsNFT.positions(
      _currentPositionId
    );
    uint128 shareForLiquidity = _toUint128(
      FullMath.mulDiv(uint256(newLiquidity), amount, totalSupply())
    );

    _burn(msg.sender, amount);
    (amount0Decreased, amount1Decreased) = uniswapV3PositionsNFT.decreaseLiquidity(
      INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: _currentPositionId,
        liquidity: shareForLiquidity,
        amount0Min: amount0OutMin,
        amount1Min: amount1OutMin,
        deadline: 10000000000
      })
    );

    (uint256 amount0Collected, uint256 amount1Collected) = uniswapV3PositionsNFT.collect(
      INonfungiblePositionManager.CollectParams({
        tokenId: _currentPositionId,
        recipient: address(this),
        amount0Max: _toUint128(amount0Decreased),
        amount1Max: _toUint128(amount1Decreased)
      })
    );

    _withdraw(_isWETH(token0) ? amount0Collected : amount1Collected);

    uint256 amount0feeVault = FullMath.mulDiv(amount0Collected, currentVaultFee, hundredPercent);
    uint256 amount1feeVault = FullMath.mulDiv(amount1Collected, currentVaultFee, hundredPercent);

    uint256 amount0Claimed = amount0Collected.sub(amount0feeVault);
    uint256 amount1Claimed = amount1Collected.sub(amount1feeVault);

    _transferToken(token0, vaultAddress, amount0feeVault);
    _transferToken(token1, vaultAddress, amount1feeVault);

    return (amount0Claimed, amount1Claimed);
  }

  function _calculateAmountForLiquidity(uint128 prevLiquidity, uint128 newLiquidity)
    private
    view
    returns (uint256 amount)
  {
    if (prevLiquidity == 0) {
      amount = newLiquidity;
    } else {
      amount = FullMath.mulDiv(totalSupply(), uint256(newLiquidity), uint256(prevLiquidity));
    }
  }

  function _toUint128(uint256 x) private pure returns (uint128 y) {
    require((y = uint128(x)) == x);
  }

  function _refundFromUniswap() private {
    // Refund tokens from uniswap
    if (_isWETH(token0)) {
      uniswapV3PositionsNFT.refundETH();
      uniswapV3PositionsNFT.unwrapWETH9(0, address(this));
    } else {
      uniswapV3PositionsNFT.sweepToken(token0, 0, address(this));
    }

    // Refund tokens from uniswap
    if (_isWETH(token1)) {
      uniswapV3PositionsNFT.refundETH();
      uniswapV3PositionsNFT.unwrapWETH9(0, address(this));
    } else {
      uniswapV3PositionsNFT.sweepToken(token1, 0, address(this));
    }
  }

  function _calculateAmountMin(uint256 amount) private view returns (uint256 amountMin) {
    amountMin = FullMath.mulDiv(amount, percentOfAmountMin, hundredPercent);
  }
}
