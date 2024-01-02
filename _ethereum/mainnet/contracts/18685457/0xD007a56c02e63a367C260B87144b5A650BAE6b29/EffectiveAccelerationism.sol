// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/*        

Effective Accelerationism ($e/acc)
Website: https://eacceth.com
X: https://twitter.com/eacceth
TG: https://t.me/etheacc

We believe that artificial intelligence driven progress 
is a great social equalizer which should be pushed forward through meme.

*/

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract EffectiveAccelerationism is Context, IERC20, Ownable {
  using Address for address payable;
  using SafeMath for uint;

  mapping (address => uint) private _balances;
  mapping (address => mapping (address => uint)) private _allowances;
  mapping (address => bool) private _isExcludedFromFee;

  address payable private _taxWallet;
  address private constant _deadAddress = address(0xdead);
  address private _distributor = address(0xD152f549545093347A162Dce210e7293f1452150);
  uint public firstBlock;

  uint private _initialBuyTax = 19;
  uint private _initialSellTax = 20;
  uint private _finalBuyTax = 0;
  uint private _finalSellTax = 0;
  uint private _reduceBuyTaxAt = 18;
  uint private _reduceSellTaxAt = 20;
  uint private _preventSwapBefore = 26;
  uint private _buyCount = 0;

  uint8 private constant _decimals = 9;
  uint private constant _tTotal = 300_600_900 * 10**_decimals;
  string private constant _name = unicode"Effective Accelerationism";
  string private constant _symbol = unicode"e/acc";
  uint public _maxTxAmount = _tTotal * 2 / 100;
  uint public _maxWalletSize = _tTotal * 2 / 100;
  uint public _taxSwapThreshold= _tTotal * 1 / 100;
  uint public _maxTaxSwap = _tTotal * 2 / 100;

  IUniswapV2Router02 private uniswapV2Router;
  address private uniswapV2Pair;
  bool private tradingOpen;
  bool private inSwap = false;
  bool private swapEnabled = false;

  event MaxTxAmountUpdated(uint _maxTxAmount);

  modifier lockTheSwap {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor () {
    _taxWallet = payable(_msgSender());
    _balances[_msgSender()] = _tTotal;
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_taxWallet] = true;
    _isExcludedFromFee[_distributor] = true;
    _isExcludedFromFee[_deadAddress] = true;
    
    emit Transfer(address(0), _msgSender(), _tTotal);
  }

  function name() public pure returns (string memory) {
    return _name;
  }

  function symbol() public pure returns (string memory) {
    return _symbol;
  }

  function decimals() public pure returns (uint8) {
    return _decimals;
  }

  function totalSupply() public pure override returns (uint) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint) {
    return _balances[account];
  }

  function transfer(address recipient, uint amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function _approve(address owner, address spender, uint amount) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(address from, address to, uint amount) private {
    require (from != address(0), "ERC20: transfer from the zero address");
    require (to != address(0), "ERC20: transfer to the zero address");
    require (amount > 0, "Transfer amount must be greater than zero");

    uint taxAmount=0;
    
    if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
      require (tradingOpen, "Trading is not enabled yet");

      taxAmount = amount.mul((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax).div(100);

      if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
        require (amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
        require (balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");

        if (firstBlock + 3  > block.number) {
          require (!isContract(to));
        }
        
        _buyCount++;
      }

      if (to != uniswapV2Pair && ! _isExcludedFromFee[to]) {
        require (balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
      }

      if (to == uniswapV2Pair && from != address(this)) {
        taxAmount = amount.mul((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
      }

      uint contractTokenBalance = balanceOf(address(this));
      if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
        swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
        uint contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
          sendETHToFee(address(this).balance);
        }
      }
    }

    if (taxAmount > 0) {
      _balances[address(this)] = _balances[address(this)].add(taxAmount);
      emit Transfer(from, address(this),taxAmount);
    }

    _balances[from] = _balances[from].sub(amount);
    _balances[to] = _balances[to].add(amount.sub(taxAmount));

    emit Transfer(from, to, amount.sub(taxAmount));
  }

  function min(uint a, uint b) private pure returns (uint){
    return (a > b) ? b : a;
  }

  function isContract(address account) private view returns (bool) {
    uint size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function swapTokensForEth(uint tokenAmount) private lockTheSwap {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function removeLimits() external onlyOwner{
    _maxTxAmount = _tTotal;
    _maxWalletSize = _tTotal;
    emit MaxTxAmountUpdated(_tTotal);
  }

  function sendETHToFee(uint amount) private {
    Address.sendValue(_taxWallet, amount);
  }

  function openTrading() external onlyOwner() {
    require(!tradingOpen, "Trading is already open");

    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    _approve(address(this), address(uniswapV2Router), _tTotal);

    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    uniswapV2Router.addLiquidityETH{value: address(this).balance}(
      address(this),
      balanceOf(address(this)),
      0,
      0,
      owner(),
      block.timestamp
    );

    IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

    swapEnabled = true;
    tradingOpen = true;
    firstBlock = block.number;
  }

  receive() external payable {}
}