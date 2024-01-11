/*********************************************************************************
Giggity (GGTY)

GiggityGiggityGiggityGiggityGiggityGiggityGiggityGiggityGiggityGiggityGiggityGiggity...

"I Was Living The Life, Just Banging Chicks And Eating Cabbage." - Quagmire

SUPPLY

1,000,000,000 GGTY

TOKENOMICS

buy: 4% auto LP tax
sell: 4-16% tax (see EARLY SELL TAX below)

EARLY SELL TAX

There is a downward sell tax that rewards you by taxing less the longer you hold your GGTY.
At the point you buy, to sell you will be charged 4x the normal tax (16%). Every hour your
sell tax is decreased from 16% to 4% if you hold for >=8 hours.

COMMUNITY

Giggity supporters and community should build the twitter, telegram, and make something that lasts forever.
*********************************************************************************/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract Giggity is ERC20, Ownable {
  uint256 public constant EARLY_SELL_MULT = 4;
  uint256 public constant EARLY_TAPER_HOURS = 8;
  uint256 private constant HOUR = 60 * 60;
  uint256 private constant DENOM = 1000;

  mapping(address => bool) private _taxExcluded;

  uint256 private _taxLiquidity = 40; // 4%

  uint256 private _liquifyRate = 10;
  uint256 public theLaunchTime;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  mapping(address => uint256) private _lastBuy;
  mapping(address => bool) private _isBot;

  bool private _swapEnabled = true;
  bool private _swapping = false;

  modifier lockTheSwap() {
    _swapping = true;
    _;
    _swapping = false;
  }

  constructor() ERC20('Giggity', 'GGTY') {
    _mint(address(this), 69_690_420_420 * 10**18);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );
    uniswapV2Router = _uniswapV2Router;
    _taxExcluded[address(this)] = true;
    _taxExcluded[msg.sender] = true;
  }

  function ripIt() external payable onlyOwner {
    require(theLaunchTime == 0, 'already launched');
    require(msg.value > 0, 'need ETH for initial LP');
    _addLiquidity(totalSupply(), msg.value);
    theLaunchTime = block.timestamp;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isOwner = sender == owner() || recipient == owner();
    require(!_isBot[recipient], 'Stop botting!');
    require(!_isBot[sender], 'Stop botting!');
    require(!_isBot[_msgSender()], 'Stop botting!');
    uint256 contractTokenBalance = balanceOf(address(this));

    bool _isBuy = sender == uniswapV2Pair &&
      recipient != address(uniswapV2Router);
    bool _isSell = recipient == uniswapV2Pair;
    if (_isBuy) {
      _lastBuy[recipient] = block.timestamp;

      if (block.timestamp == theLaunchTime) {
        _isBot[recipient] = true;
      }
    }

    uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) / DENOM;
    bool _overMin = contractTokenBalance >= _minSwap;
    if (
      _swapEnabled &&
      !_swapping &&
      !_isOwner &&
      _overMin &&
      theLaunchTime != 0 &&
      sender != uniswapV2Pair
    ) {
      _swap(_minSwap);
    }

    uint256 tax = 0;
    if (
      theLaunchTime != 0 && !(_taxExcluded[sender] || _taxExcluded[recipient])
    ) {
      tax = (amount * _taxLiquidity) / DENOM;
      if (tax > 0) {
        if (_isSell) {
          tax = calculateEarlyTax(sender, tax);
        }
        super._transfer(sender, address(this), tax);
      }
    }

    super._transfer(sender, recipient, amount - tax);
  }

  function _swap(uint256 contractTokenBalance) private lockTheSwap {
    uint256 balBefore = address(this).balance;
    uint256 liquidityTokens = contractTokenBalance / 2;
    uint256 tokensToSwap = contractTokenBalance - liquidityTokens;

    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokensToSwap);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokensToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 balToProcess = address(this).balance - balBefore;
    if (balToProcess > 0 && liquidityTokens > 0) {
      _addLiquidity(liquidityTokens, balToProcess);
    }
  }

  function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      owner(),
      block.timestamp
    );
  }

  function calculateEarlyTax(address _sender, uint256 _tax)
    public
    view
    returns (uint256)
  {
    if (block.timestamp < calculateEarlyExpiration(_sender)) {
      uint256 _hoursAfterBuy = (block.timestamp - _lastBuy[_sender]) / HOUR;
      return
        (_tax * ((EARLY_SELL_MULT * EARLY_TAPER_HOURS) - _hoursAfterBuy)) /
        EARLY_TAPER_HOURS;
    }
    return _tax;
  }

  function calculateEarlyExpiration(address _sender)
    public
    view
    returns (uint256)
  {
    return _lastBuy[_sender] + (EARLY_TAPER_HOURS * HOUR);
  }

  function setTaxLp(uint256 _tax) external onlyOwner {
    _taxLiquidity = _tax;
  }

  function setLiquifyRate(uint256 _rate) external onlyOwner {
    require(_rate <= DENOM / 10, 'cannot be more than 10%');
    _liquifyRate = _rate;
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    _taxExcluded[_wallet] = _isExcluded;
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }

  receive() external payable {}
}
