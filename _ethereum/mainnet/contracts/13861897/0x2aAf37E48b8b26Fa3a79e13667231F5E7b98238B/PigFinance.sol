/**
   #PIG
   
   #LIQ+#RFI+#SHIB+#DOGE, combine together to #PIG  

    I make this #PIG to hand over it to the community.
    Create the community by yourself if you are interested.   

   Great features:
    1. 4% marketing - on every transfer we take out 4% of the trade, convert tokens to native (BNB) and deliver to marketing address
    2. 3% liquidity - on every transfer we take out 3% of the trade, convert half to native (BNB) and provide liquidity in your primary liquidity pool
    3. 3% burn - on every transfer we take out 3% of the trade and send those tokens directly to the burn address.
    4. 3% reflections - holders redistribution on every transfer we take out 3% of the trade and send those pigVerse directly to the holders.

   I will burn liquidity LPs to burn addresses to lock the pool forever.
   I will renounce the ownership to burn addresses to transfer #PIG to the community, make sure it's 100% safe.

   1,000,000,000,000,000 total supply

   3% fee for liquidity will go to an address that the contract creates, 
   and the contract will sell it and add to liquidity automatically, 
   it's the best part of the #PIG idea, increasing the liquidity pool automatically, 
   help the pool grow from the small init pool.
**/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract PigFinance is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  address payable public marketingWallet =
    payable(0x2a5a481b1A90abD076e37037dAFC49A67cCb3B7f);
  address public constant deadAddress =
    0x000000000000000000000000000000000000dEaD;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isSniper;
  address[] private _confirmedSnipers;

  mapping(address => bool) private _isExcludedFee;
  mapping(address => bool) private _isExcludedReward;
  address[] private _excluded;

  string private constant _name = 'Pig Finance';
  string private constant _symbol = 'PIG';
  uint8 private constant _decimals = 9;

  uint256 private constant MAX = ~uint256(0);
  uint256 private constant _tTotal = 10**15 * 10**_decimals;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;

  uint256 public reflectionFee = 3;
  uint256 private _previousReflectFee = reflectionFee;

  uint256 public marketingFee = 4;
  uint256 private _previousMarketingFee = marketingFee;

  uint256 public burnFee = 3;
  uint256 private _previousBurnFee = burnFee;

  uint256 public lpFee = 3;
  uint256 private _previousLpFee = lpFee;

  uint256 public feeRate = 2;
  uint256 public launchTime;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  // PancakeSwap: 0x10ED43C718714eb63d5aA57B78B54704E256024E
  // Uniswap V2: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  address private constant _uniswapRouterAddress =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  bool private _inSwapAndLiquify;
  bool private _tradingOpen = false;

  event AddLiquidity(uint256 amountTokens, uint256 amountETH);
  event Send_previousBurnFeewards(address to, uint256 amountETH);
  event SendTokenRewards(address to, address token, uint256 amount);
  event SwapTokensForETH(uint256 amountIn, address[] path);
  event SwapAndLiquify(
    uint256 tokensSwappedForEth,
    uint256 ethAddedForLp,
    uint256 tokensAddedForLp
  );

  modifier lockTheSwap() {
    _inSwapAndLiquify = true;
    _;
    _inSwapAndLiquify = false;
  }

  constructor() {
    _rOwned[_msgSender()] = _rTotal;
    emit Transfer(address(0), _msgSender(), _tTotal);
  }

  function initContract() external onlyOwner {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      _uniswapRouterAddress
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    uniswapV2Router = _uniswapV2Router;

    _isExcludedFee[owner()] = true;
    _isExcludedFee[address(this)] = true;
  }

  function openTrading() external onlyOwner {
    marketingFee = _previousMarketingFee;
    burnFee = _previousBurnFee;
    reflectionFee = _previousReflectFee;
    lpFee = _previousLpFee;
    _tradingOpen = true;
    launchTime = block.timestamp;
  }

  function name() external pure returns (string memory) {
    return _name;
  }

  function symbol() external pure returns (string memory) {
    return _symbol;
  }

  function decimals() external pure returns (uint8) {
    return _decimals;
  }

  function totalSupply() external pure override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcludedReward[account]) return _tOwned[account];
    return tokenFromReflection(_rOwned[account]);
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        'ERC20: transfer amount exceeds allowance'
      )
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    external
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function totalFees() external view returns (uint256) {
    return _tFeeTotal;
  }

  function deliver(uint256 tAmount) external {
    address sender = _msgSender();
    require(
      !_isExcludedReward[sender],
      'Excluded addresses cannot call this function'
    );
    (uint256 rAmount, , , , , , ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rTotal = _rTotal.sub(rAmount);
    _tFeeTotal = _tFeeTotal.add(tAmount);
  }

  function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
    external
    view
    returns (uint256)
  {
    require(tAmount <= _tTotal, 'Amount must be less than supply');
    if (!deductTransferFee) {
      (uint256 rAmount, , , , , , ) = _getValues(tAmount);
      return rAmount;
    } else {
      (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
      return rTransferAmount;
    }
  }

  function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
    require(rAmount <= _rTotal, 'Amount must be less than total reflections');
    uint256 currentRate = _getRate();
    return rAmount.div(currentRate);
  }

  function excludeFromReward(address account) external onlyOwner {
    require(!_isExcludedReward[account], 'Account is already excluded');
    if (_rOwned[account] > 0) {
      _tOwned[account] = tokenFromReflection(_rOwned[account]);
    }
    _isExcludedReward[account] = true;
    _excluded.push(account);
  }

  function includeInReward(address account) external onlyOwner {
    require(_isExcludedReward[account], 'Account is already included');
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _tOwned[account] = 0;
        _isExcludedReward[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(amount > 0, 'Transfer amount must be greater than zero');
    require(!_isSniper[to], 'Stop sniping!');
    require(!_isSniper[from], 'Stop sniping!');
    require(!_isSniper[_msgSender()], 'Stop sniping!');

    bool excludedFromFee = _isExcludedFee[from] || _isExcludedFee[to];

    // buy
    if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
      require(_tradingOpen, 'trading is not open yet');
    }

    // sell
    if (!_inSwapAndLiquify && _tradingOpen && to == uniswapV2Pair) {
      uint256 _contractTokenBalance = balanceOf(address(this));
      if (_contractTokenBalance > 0) {
        if (
          _contractTokenBalance > balanceOf(uniswapV2Pair).mul(feeRate).div(100)
        ) {
          _contractTokenBalance = balanceOf(uniswapV2Pair).mul(feeRate).div(
            100
          );
        }
        _swapTokens(_contractTokenBalance);
      }
    }

    bool takeFee = true;
    if (excludedFromFee) {
      takeFee = false;
    }

    _tokenTransfer(from, to, amount, takeFee);
  }

  function _swapTokens(uint256 _contractTokenBalance) private lockTheSwap {
    uint256 ethBalanceBefore = address(this).balance;
    uint256 _liquidityFeeTotal = _liquidityFeeAggregate();

    // Leave half of LP tokens from total contract balance to be used to add liquidity to Uniswap
    uint256 ethSwapTokens = _contractTokenBalance
      .mul(_liquidityFeeTotal.sub(lpFee))
      .div(_liquidityFeeTotal);
    uint256 lpTokens = _contractTokenBalance.sub(ethSwapTokens);

    _swapTokensForEth(ethSwapTokens);
    uint256 ethBalanceAfter = address(this).balance;
    uint256 ethBalanceUpdate = ethBalanceAfter.sub(ethBalanceBefore);

    // send ETH to marketing address
    uint256 marketingETHBalance = ethBalanceUpdate.mul(marketingFee).div(
      _liquidityFeeTotal
    );
    if (marketingETHBalance > 0) {
      _sendETHToMarketing(marketingETHBalance);
    }

    // add to liquidity pool
    uint256 lpETHBalance = ethBalanceUpdate.sub(marketingETHBalance);
    if (lpETHBalance > 0) {
      _addLp(lpTokens, lpETHBalance);
    }
  }

  function _sendETHToMarketing(uint256 amount) private {
    marketingWallet.call{ value: amount }('');
  }

  function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      deadAddress,
      block.timestamp
    );
    emit AddLiquidity(tokenAmount, ethAmount);
  }

  function _swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this), // the contract
      block.timestamp
    );

    emit SwapTokensForETH(tokenAmount, path);
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount,
    bool takeFee
  ) private {
    if (!takeFee) _removeAllFee();

    if (_isExcludedReward[sender] && !_isExcludedReward[recipient]) {
      _transferFromExcluded(sender, recipient, amount);
    } else if (!_isExcludedReward[sender] && _isExcludedReward[recipient]) {
      _transferToExcluded(sender, recipient, amount);
    } else if (_isExcludedReward[sender] && _isExcludedReward[recipient]) {
      _transferBothExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }

    if (!takeFee) _restoreAllFee();
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity,
      uint256 tBurn
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeBurn(tBurn);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity,
      uint256 tBurn
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeBurn(tBurn);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity,
      uint256 tBurn
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeBurn(tBurn);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 tAmount
  ) private {
    (
      uint256 rAmount,
      uint256 rTransferAmount,
      uint256 rFee,
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity,
      uint256 tBurn
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeBurn(tBurn);
    _reflectFee(rFee, tFee);
    emit Transfer(sender, recipient, tTransferAmount);
  }

  function _reflectFee(uint256 rFee, uint256 tFee) private {
    _rTotal = _rTotal.sub(rFee);
    _tFeeTotal = _tFeeTotal.add(tFee);
  }

  function _getValues(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    (
      uint256 tTransferAmount,
      uint256 tFee,
      uint256 tLiquidity,
      uint256 tBurn
    ) = _getTValues(tAmount);
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
      tAmount,
      tFee,
      tLiquidity,
      tBurn,
      _getRate()
    );
    return (
      rAmount,
      rTransferAmount,
      rFee,
      tTransferAmount,
      tFee,
      tLiquidity,
      tBurn
    );
  }

  function _getTValues(uint256 tAmount)
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 tFee = _calculateReflectFee(tAmount);
    uint256 tLiquidity = _calculateLiquidityFee(tAmount);
    uint256 tBurn = _calculateBurnFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tBurn);
    return (tTransferAmount, tFee, tLiquidity, tBurn);
  }

  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 tLiquidity,
    uint256 tBurn,
    uint256 currentRate
  )
    private
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 rAmount = tAmount.mul(currentRate);
    uint256 rFee = tFee.mul(currentRate);
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    uint256 rBurn = tBurn.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rBurn);
    return (rAmount, rTransferAmount, rFee);
  }

  function _getRate() private view returns (uint256) {
    (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
    return rSupply.div(tSupply);
  }

  function _getCurrentSupply() private view returns (uint256, uint256) {
    uint256 rSupply = _rTotal;
    uint256 tSupply = _tTotal;
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply)
        return (_rTotal, _tTotal);
      rSupply = rSupply.sub(_rOwned[_excluded[i]]);
      tSupply = tSupply.sub(_tOwned[_excluded[i]]);
    }
    if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
    return (rSupply, tSupply);
  }

  function _takeLiquidity(uint256 tLiquidity) private {
    uint256 currentRate = _getRate();
    uint256 rLiquidity = tLiquidity.mul(currentRate);
    _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    if (_isExcludedReward[address(this)])
      _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
  }

  function _takeBurn(uint256 tBurn) private {
    uint256 currentRate = _getRate();
    uint256 rBurn = tBurn.mul(currentRate);
    _rOwned[deadAddress] = _rOwned[deadAddress].add(rBurn);
    if (_isExcludedReward[deadAddress])
      _tOwned[deadAddress] = _tOwned[deadAddress].add(tBurn);
  }

  function _calculateReflectFee(uint256 _amount)
    private
    view
    returns (uint256)
  {
    return _amount.mul(reflectionFee).div(10**2);
  }

  function _calculateLiquidityFee(uint256 _amount)
    private
    view
    returns (uint256)
  {
    return _amount.mul(_liquidityFeeAggregate()).div(10**2);
  }

  function _calculateBurnFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(burnFee).div(10**2);
  }

  function _liquidityFeeAggregate() private view returns (uint256) {
    return marketingFee.add(lpFee);
  }

  function _removeAllFee() private {
    if (reflectionFee == 0 && marketingFee == 0 && burnFee == 0 && lpFee == 0)
      return;

    _previousReflectFee = reflectionFee;
    _previousMarketingFee = marketingFee;
    _previousBurnFee = burnFee;
    _previousLpFee = lpFee;

    reflectionFee = 0;
    marketingFee = 0;
    burnFee = 0;
    lpFee = 0;
  }

  function _restoreAllFee() private {
    reflectionFee = _previousReflectFee;
    marketingFee = _previousMarketingFee;
    burnFee = _previousBurnFee;
    lpFee = _previousLpFee;
  }

  function isExcludedFromReward(address account) external view returns (bool) {
    return _isExcludedReward[account];
  }

  function excludeFromFee(address account) external onlyOwner {
    _isExcludedFee[account] = true;
  }

  function includeInFee(address account) external onlyOwner {
    _isExcludedFee[account] = false;
  }

  function setReflectionFeePercent(uint256 _newFee) external onlyOwner {
    require(_newFee <= 10, 'fee cannot exceed 10%');
    reflectionFee = _newFee;
  }

  function setMarketingFeePercent(uint256 _newFee) external onlyOwner {
    require(_newFee <= 10, 'fee cannot exceed 10%');
    marketingFee = _newFee;
  }

  function setBurnFeePercent(uint256 _newFee) external onlyOwner {
    require(_newFee <= 10, 'fee cannot exceed 10%');
    burnFee = _newFee;
  }

  function setLpFeePercent(uint256 _newFee) external onlyOwner {
    require(_newFee <= 10, 'fee cannot exceed 10%');
    lpFee = _newFee;
  }

  function setMarketingAddress(address _marketingWallet) external onlyOwner {
    marketingWallet = payable(_marketingWallet);
  }

  function isRemovedSniper(address account) external view returns (bool) {
    return _isSniper[account];
  }

  function removeSniper(address account) external onlyOwner {
    require(account != _uniswapRouterAddress, 'We can not blacklist Uniswap');
    require(!_isSniper[account], 'Account is already blacklisted');
    _isSniper[account] = true;
    _confirmedSnipers.push(account);
  }

  function amnestySniper(address account) external onlyOwner {
    require(_isSniper[account], 'Account is not blacklisted');
    for (uint256 i = 0; i < _confirmedSnipers.length; i++) {
      if (_confirmedSnipers[i] == account) {
        _confirmedSnipers[i] = _confirmedSnipers[_confirmedSnipers.length - 1];
        _isSniper[account] = false;
        _confirmedSnipers.pop();
        break;
      }
    }
  }

  function setFeeRate(uint256 _rate) external onlyOwner {
    feeRate = _rate;
  }

  function emergencyWithdraw() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }

  // to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}
}
