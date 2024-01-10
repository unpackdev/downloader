// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract GN is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  address private constant BURN_ADDRESS = address(0xdead);

  uint8 public marketingPercent = 50; // 0-100%, splits with nightverse wallet
  address payable public marketingDevAddress =
    payable(0xd9ecB6138923107bdd77Ef0fB635BDDEdAa87D1e);
  address payable public nightverseAddress =
    payable(0xC6600d61528c536971c3dD778a076baB5c8b163d);

  // PancakeSwap: 0x10ED43C718714eb63d5aA57B78B54704E256024E
  // Uniswap V2: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  address private constant DEX_ROUTER =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  mapping(address => uint256) private _rOwned;
  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isSniper;
  address[] private _confirmedSnipers;

  mapping(address => bool) private _isExcludedFee;
  mapping(address => bool) private _isExcludedReward;
  address[] private _excluded;

  string private constant _name = 'GN';
  string private constant _symbol = 'GN';
  uint8 private constant _decimals = 9;

  uint256 private constant MAX = ~uint256(0);
  uint256 private constant _tTotal = 1_000_000_000_000 * 10**_decimals;
  uint256 private _rTotal = (MAX - (MAX % _tTotal));
  uint256 private _tFeeTotal;

  uint256 public buyReflectionFee = 0;
  uint256 public sellReflectionFee = 0;
  uint256 private _previousBuyReflectFee = buyReflectionFee;
  uint256 private _previousSellReflectFee = sellReflectionFee;

  uint256 public buyInternalFee = 8; // split between marketing/dev & nightverse
  uint256 public sellInternalFee = 8;
  uint256 private _previousBuyInternalFee = buyInternalFee;
  uint256 private _previousSellInternalFee = sellInternalFee;

  uint256 public buyBurnFee = 0;
  uint256 public sellBurnFee = 2;
  uint256 private _previousBuyBurnFee = buyBurnFee;
  uint256 private _previousSellBurnFee = sellBurnFee;

  uint256 public buyLpFee = 3;
  uint256 public sellLpFee = 3;
  uint256 private _previousBuyLpFee = buyLpFee;
  uint256 private _previousSellLpFee = sellLpFee;

  bool isSelling = false;
  uint256 public liquifyRate = 2;
  uint256 public launchTime;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;
  mapping(address => bool) private _isUniswapPair;

  bool private _inSwapAndLiquify;
  bool private _tradingOpen = false;

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
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(DEX_ROUTER);
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    uniswapV2Router = _uniswapV2Router;

    _isExcludedFee[owner()] = true;
    _isExcludedFee[address(this)] = true;
  }

  function openTrading() external onlyOwner {
    buyInternalFee = _previousBuyInternalFee;
    buyReflectionFee = _previousBuyReflectFee;
    buyBurnFee = _previousBuyBurnFee;
    buyLpFee = _previousBuyLpFee;

    sellInternalFee = _previousSellInternalFee;
    sellReflectionFee = _previousSellReflectFee;
    sellBurnFee = _previousSellBurnFee;
    sellLpFee = _previousSellLpFee;

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
      isSelling = true;
      uint256 _contractTokenBalance = balanceOf(address(this));
      if (_contractTokenBalance > 0) {
        if (
          _contractTokenBalance >
          balanceOf(uniswapV2Pair).mul(liquifyRate).div(100)
        ) {
          _contractTokenBalance = balanceOf(uniswapV2Pair).mul(liquifyRate).div(
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
    isSelling = false;
  }

  function _swapTokens(uint256 _contractTokenBalance) private lockTheSwap {
    uint256 _lpFee = buyLpFee.add(sellLpFee);
    uint256 _internalFee = buyInternalFee.add(sellInternalFee);
    uint256 _totalFee = _lpFee.add(_internalFee);
    uint256 _lpTokens = _contractTokenBalance.mul(_lpFee).div(_totalFee).div(2);
    uint256 _tokensToSwap = _contractTokenBalance.sub(_lpTokens);
    uint256 _balanceBefore = address(this).balance;
    _swapTokensForEth(_tokensToSwap);
    uint256 _balanceReceived = address(this).balance.sub(_balanceBefore);

    uint256 _marketingETH = _balanceReceived.mul(_internalFee).div(_totalFee);
    uint256 _lpETH = _balanceReceived.sub(_marketingETH);
    if (_marketingETH > 0) {
      _sendETHToInternal(_marketingETH);
    }
    if (_lpETH > 0) {
      _addLp(_lpTokens, _lpETH);
    }
  }

  function _sendETHToInternal(uint256 amount) private {
    uint256 marketingAmount = amount.mul(marketingPercent).div(100);
    uint256 nightverseAmount = amount.sub(marketingAmount);
    marketingDevAddress.call{ value: marketingAmount }('');
    nightverseAddress.call{ value: nightverseAmount }('');
  }

  function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      marketingDevAddress,
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

  function _takeBurn(uint256 _tBurn) private {
    uint256 currentRate = _getRate();
    uint256 rDev = _tBurn.mul(currentRate);
    _rOwned[BURN_ADDRESS] = _rOwned[BURN_ADDRESS].add(rDev);
    if (_isExcludedReward[BURN_ADDRESS])
      _tOwned[BURN_ADDRESS] = _tOwned[BURN_ADDRESS].add(_tBurn);
  }

  function _calculateReflectFee(uint256 _amount)
    private
    view
    returns (uint256)
  {
    uint256 fee = isSelling ? sellReflectionFee : buyReflectionFee;
    return _amount.mul(fee).div(10**2);
  }

  function _calculateLiquidityFee(uint256 _amount)
    private
    view
    returns (uint256)
  {
    uint256 fee = isSelling
      ? sellInternalFee.add(sellLpFee)
      : buyInternalFee.add(buyLpFee);
    return _amount.mul(fee).div(10**2);
  }

  function _calculateBurnFee(uint256 _amount) private view returns (uint256) {
    uint256 fee = isSelling ? sellBurnFee : buyBurnFee;
    return _amount.mul(fee).div(10**2);
  }

  function _calculateLpFee(uint256 _amount) private view returns (uint256) {
    uint256 fee = isSelling ? sellLpFee : buyLpFee;
    return _amount.mul(fee).div(10**2);
  }

  function _removeAllFee() private {
    _previousBuyReflectFee = buyReflectionFee;
    _previousBuyInternalFee = buyInternalFee;
    _previousBuyBurnFee = buyBurnFee;
    _previousBuyLpFee = buyLpFee;

    _previousSellReflectFee = sellReflectionFee;
    _previousSellInternalFee = sellInternalFee;
    _previousSellBurnFee = sellBurnFee;
    _previousSellLpFee = sellLpFee;

    buyReflectionFee = 0;
    buyInternalFee = 0;
    buyBurnFee = 0;

    sellReflectionFee = 0;
    sellInternalFee = 0;
    sellBurnFee = 0;
  }

  function _restoreAllFee() private {
    buyReflectionFee = _previousBuyReflectFee;
    buyInternalFee = _previousBuyInternalFee;
    buyBurnFee = _previousBuyBurnFee;

    sellReflectionFee = _previousSellReflectFee;
    sellInternalFee = _previousSellInternalFee;
    sellBurnFee = _previousSellBurnFee;
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

  function setReflectionFeePercent(uint256 _buy, uint256 _sell)
    external
    onlyOwner
  {
    require(_buy <= 25, 'cannot be above 25%');
    require(
      _buy.add(buyInternalFee).add(buyBurnFee).add(buyLpFee) <= 25,
      'overall fees cannot be above 25%'
    );
    buyReflectionFee = _buy;

    require(_sell <= 25, 'cannot be above 25%');
    require(
      _sell.add(sellInternalFee).add(sellBurnFee).add(sellLpFee) <= 25,
      'overall fees cannot be above 25%'
    );
    sellReflectionFee = _sell;
  }

  function setInternalFeePercent(uint256 _buy, uint256 _sell)
    external
    onlyOwner
  {
    require(_buy <= 25, 'cannot be above 25%');
    require(
      _buy.add(buyReflectionFee).add(buyBurnFee).add(buyLpFee) <= 25,
      'overall fees cannot be above 25%'
    );
    buyInternalFee = _buy;

    require(_sell <= 25, 'cannot be above 25%');
    require(
      _sell.add(sellReflectionFee).add(sellBurnFee).add(sellLpFee) <= 25,
      'overall fees cannot be above 25%'
    );
    sellInternalFee = _sell;
  }

  function setBurnFeePercent(uint256 _buy, uint256 _sell) external onlyOwner {
    require(_buy <= 25, 'cannot be above 25%');
    require(
      _buy.add(buyInternalFee).add(buyReflectionFee).add(buyLpFee) <= 25,
      'overall fees cannot be above 25%'
    );
    buyBurnFee = _buy;

    require(_sell <= 25, 'cannot be above 25%');
    require(
      _sell.add(sellInternalFee).add(sellReflectionFee).add(sellLpFee) <= 25,
      'overall fees cannot be above 25%'
    );
    sellBurnFee = _sell;
  }

  function setLpFeePercent(uint256 _buy, uint256 _sell) external onlyOwner {
    require(_buy <= 25, 'cannot be above 25%');
    require(
      _buy.add(buyInternalFee).add(buyReflectionFee).add(buyBurnFee) <= 25,
      'overall fees cannot be above 25%'
    );
    buyLpFee = _buy;

    require(_sell <= 25, 'cannot be above 25%');
    require(
      _sell.add(sellInternalFee).add(sellReflectionFee).add(sellBurnFee) <= 25,
      'overall fees cannot be above 25%'
    );
    sellLpFee = _sell;
  }

  function setInternalAddresses(
    address _marketingDevAddress,
    address _nightverseAddress
  ) external onlyOwner {
    marketingDevAddress = payable(_marketingDevAddress);
    nightverseAddress = payable(_nightverseAddress);
  }

  function setMarketingPercent(uint8 perc) external onlyOwner {
    require(perc <= 100, 'can only be 0-100');
    marketingPercent = perc;
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
    _amount = _amount == 0 ? address(this).balance : _amount;
    _recipient.call{ value: _amount }('');
  }

  function isRemovedSniper(address account) external view returns (bool) {
    return _isSniper[account];
  }

  function removeSniper(address account) external onlyOwner {
    require(account != DEX_ROUTER, 'We can not blacklist Uniswap');
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

  function setLiquifyRate(uint256 rate) external onlyOwner {
    liquifyRate = rate;
  }

  // to recieve ETH from uniswapV2Router when swaping
  receive() external payable {}
}
