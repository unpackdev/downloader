/*

MUSO
MUSO_Finance


Website = www.muso.finance
Telegram = https://t.me/MUSOfinance
Twitter = @musofinance
Instagram @musofinance_

Idea to innovation – MUSO Finance was founded in 2021 by likeminded people 
whom all have a keen interest in music and crypto.

With MUSO Finance being the driving force of various projects the team have 
every intention to be at the forefront of the music industry, offering fair 
payment to all artists and zestful community events.

Idea to innovation – MUSO Finance was founded in 2021 by likeminded people 
whom all have a keen interest in music and crypto.

With MUSO Finance being the driving force of various projects the team have 
every intention to be at the forefront of the music industry, offering fair 
payment to all artists and zestful community events.

3% Reflection - Just hold and get more tokens! 
4% Auto Liquidity - Keeps the token growing and keeps the token healthy!
3% Development - Ongoing development, ongoing growth! 

Contract created by GenTokens.com 

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract MUSO is Context, IERC20, Ownable {
  using SafeMath for uint8;
  using SafeMath for uint16;
  using SafeMath for uint48;
  using SafeMath for uint256;
  using Address for address;

  address payable public marketingAddress =
    payable(0x58dCAd629BCBA9Ba44dfe3036a0915C69D82876F);

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isSniper;
  address[] private _confirmedSnipers;

  mapping(address => bool) private _isExcludedFee;
  mapping(address => bool) private _isExcludedReward;
  address[] private _excluded;

  string private constant _name = 'MUSO Finance';
  string private constant _symbol = 'MUSO';
  uint8 private constant _decimals = 9;

  uint256 private constant MAX = ~uint256(0);
  uint256 private constant _tTotal = 100000000 * 10**_decimals;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;

  uint256 public reflectionFee = 3;
  uint256 private _previousReflectFee = reflectionFee;

  uint256 public marketingFee = 3;
  uint256 private _previousMarketingFee = marketingFee;

  uint256 public lpAddFee = 4;
  uint256 private _previousLpAddFee = lpAddFee;

  // token fee for burns and giveaways
  uint256 public tokenGiveawayFee = 0;
  uint256 private _previousTokenGiveawayFee = tokenGiveawayFee;

  uint256 public feeRate = 2;
  uint256 public launchTime;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  mapping(address => bool) private _isUniswapPair;

  // PancakeSwap: 0x10ED43C718714eb63d5aA57B78B54704E256024E
  // Uniswap V2: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  address private constant _uniswapRouterAddress =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  bool private _inSwapAndLiquify;
  bool private _tradingOpen = false;

  event SwapETHForTokens(uint256 amountIn, address[] path);
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
    lpAddFee = _previousLpAddFee;
    reflectionFee = _previousReflectFee;
    tokenGiveawayFee = _previousTokenGiveawayFee;
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

  function isExcludedFromReward(address account) external view returns (bool) {
    return _isExcludedReward[account];
  }

  function isUniswapPair(address _pair) external view returns (bool) {
    if (_pair == uniswapV2Pair) return true;
    return _isUniswapPair[_pair];
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
    require(!_isSniper[msg.sender], 'Stop sniping!');

    // buy
    if (
      from == uniswapV2Pair &&
      to != address(uniswapV2Router) &&
      !_isExcludedFee[to]
    ) {
      require(_tradingOpen, 'Trading not yet enabled.');

      // antibot
      if (block.timestamp == launchTime) {
        _isSniper[to] = true;
        _confirmedSnipers.push(to);
      }
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

    bool takeFee = false;

    // take fee only on swaps
    if (
      (from == uniswapV2Pair ||
        to == uniswapV2Pair ||
        _isUniswapPair[to] ||
        _isUniswapPair[from]) && !(_isExcludedFee[from] || _isExcludedFee[to])
    ) {
      takeFee = true;
    }

    _tokenTransfer(from, to, amount, takeFee);
  }

  function _swapTokens(uint256 _contractTokenBalance) private lockTheSwap {
    uint256 _liquidityFee = marketingFee.add(lpAddFee);
    if (_liquidityFee == 0) {
      return;
    }
    uint256 _marketingTokenBalance = _contractTokenBalance
      .mul(marketingFee)
      .div(_liquidityFee);
    _swapTokensForEth(_marketingTokenBalance);

    // send ETH to marketing address
    uint256 contractETHBalance = address(this).balance;
    if (contractETHBalance > 0) {
      _sendETHToMarketing(address(this).balance);
    }

    // add liquidity to liquidity pair
    uint256 _lpTokenBalance = _contractTokenBalance.sub(_marketingTokenBalance);
    if (_lpTokenBalance > 0) {
      uint256 _firstHalf = _lpTokenBalance.div(2);
      uint256 _secondHalf = _lpTokenBalance.sub(_firstHalf);
      uint256 _balanceBeforeLP = address(this).balance;
      _swapTokensForEth(_firstHalf);
      uint256 _swappedLP = address(this).balance.sub(_balanceBeforeLP);
      _addLiquidity(_secondHalf, _swappedLP);
      emit SwapAndLiquify(_firstHalf, _swappedLP, _secondHalf);
    }
  }

  function _sendETHToMarketing(uint256 amount) private {
    // marketingAddress.transfer(amount);
    // Ignore the boolean return value.
    marketingAddress.call{ value: amount }('');
  }

  function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
    _approve(address(this), address(uniswapV2Router), _tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: _ethAmount }(
      address(this),
      _tokenAmount,
      0,
      0,
      owner(),
      block.timestamp
    );
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
      uint256 tDev
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeDev(tDev);
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
      uint256 tDev
    ) = _getValues(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeDev(tDev);
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
      uint256 tDev
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeDev(tDev);
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
      uint256 tDev
    ) = _getValues(tAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _rOwned[sender] = _rOwned[sender].sub(rAmount);
    _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
    _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    _takeLiquidity(tLiquidity);
    _takeDev(tDev);
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
      uint256 tDev
    ) = _getTValues(tAmount);
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
      tAmount,
      tFee,
      tLiquidity,
      tDev,
      _getRate()
    );
    return (
      rAmount,
      rTransferAmount,
      rFee,
      tTransferAmount,
      tFee,
      tLiquidity,
      tDev
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
    uint256 tDev = _calculateTokenGiveawayFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tDev);
    return (tTransferAmount, tFee, tLiquidity, tDev);
  }

  function _getRValues(
    uint256 tAmount,
    uint256 tFee,
    uint256 tLiquidity,
    uint256 tDev,
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
    uint256 rDev = tDev.mul(currentRate);
    uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rDev);
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

  function _takeDev(uint256 _tDev) private {
    uint256 currentRate = _getRate();
    uint256 rDev = _tDev.mul(currentRate);
    _rOwned[marketingAddress] = _rOwned[marketingAddress].add(rDev);
    if (_isExcludedReward[marketingAddress])
      _tOwned[marketingAddress] = _tOwned[marketingAddress].add(_tDev);
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
    uint256 _liquidityFee = marketingFee.add(lpAddFee);
    return _amount.mul(_liquidityFee).div(10**2);
  }

  function _calculateTokenGiveawayFee(uint256 _amount)
    private
    view
    returns (uint256)
  {
    return _amount.mul(tokenGiveawayFee).div(10**2);
  }

  function _removeAllFee() private {
    if (
      reflectionFee == 0 &&
      marketingFee == 0 &&
      lpAddFee == 0 &&
      tokenGiveawayFee == 0
    ) return;

    _previousReflectFee = reflectionFee;
    _previousMarketingFee = marketingFee;
    _previousLpAddFee = lpAddFee;
    _previousTokenGiveawayFee = tokenGiveawayFee;

    reflectionFee = 0;
    marketingFee = 0;
    lpAddFee = 0;
    tokenGiveawayFee = 0;
  }

  function _restoreAllFee() private {
    reflectionFee = _previousReflectFee;
    marketingFee = _previousMarketingFee;
    lpAddFee = _previousLpAddFee;
    tokenGiveawayFee = _previousTokenGiveawayFee;
  }

  function isExcludedFromFee(address account) external view returns (bool) {
    return _isExcludedFee[account];
  }

  function excludeFromFee(address account) external onlyOwner {
    _isExcludedFee[account] = true;
  }

  function includeInFee(address account) external onlyOwner {
    _isExcludedFee[account] = false;
  }

  function setReflectionFeePercent(uint256 _newReflectFee) external onlyOwner {
    reflectionFee = _newReflectFee;
  }

  function setMarketingFeePercent(uint256 _newMarketingFee) external onlyOwner {
    marketingFee = _newMarketingFee;
  }

  function setLpAddFeeFeePercent(uint256 _newLpAddFee) external onlyOwner {
    lpAddFee = _newLpAddFee;
  }

  function setTokenGiveawayFeePercent(uint256 _newTokenFee) external onlyOwner {
    tokenGiveawayFee = _newTokenFee;
  }

  function setMarketingAddress(address _marketingAddress) external onlyOwner {
    marketingAddress = payable(_marketingAddress);
  }

  function addUniswapPair(address _pair) external onlyOwner {
    _isUniswapPair[_pair] = true;
  }

  function removeUniswapPair(address _pair) external onlyOwner {
    _isUniswapPair[_pair] = false;
  }

  function transferToAddressETH(address payable _recipient, uint256 _amount)
    external
    onlyOwner
  {
    // recipient.transfer(amount);
    // Ignore the boolean return value
    _recipient.call{ value: _amount }('');
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

  function setFeeRate(uint256 rate) external onlyOwner {
    feeRate = rate;
  }

  // to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}
}
