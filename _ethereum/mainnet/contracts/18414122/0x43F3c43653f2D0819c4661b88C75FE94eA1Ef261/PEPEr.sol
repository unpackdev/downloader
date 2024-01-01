// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/*        

Pepe's Sky Rocket Odyssey ($PEPEr)
https://www.peperocket.xyz/
https://t.me/PepesSkyRocketOdyssey
https://twitter.com/pepeskyrocket

*/

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract PEPEr is Context, IERC20, Ownable {
  using Address for address payable;
  using SafeMath for uint;

  mapping (address => uint) private _balances;
  mapping (address => mapping (address => uint)) private _allowances;

  mapping (address => bool) private _isExcludedFromFee;

  address private constant _deadAddress = address(0xdead);
  address payable private _marketingWallet;

  uint private _initialBuyTax = 1000; // 10%
  uint private _initialSellTax = 1000;
  uint private _finalBuyTax = 75; // 0.75%
  uint private _finalSellTax = 75;
  uint private _reduceBuyTaxAfter = 20;
  uint private _reduceSellTaxAfter = 20;
  uint private _preventSwapBefore = 20;

  uint8 private constant _decimals = 18;
  uint private constant _totalSupply = 238_855 * 10**_decimals;
  string private constant _name = unicode"Pepe's Sky Rocket Odyssey";
  string private constant _symbol = unicode"PEPEr";

  uint public _maxTxAmount = _totalSupply * 3 / 100;
  uint public _maxWalletSize = _totalSupply * 3 / 100;
  uint public _swapThreshold = _totalSupply * 1 / 1000;

  IUniswapV2Router02 private uniswapV2Router;
  address private uniswapV2Pair;

  bool private tradingOpen;
  uint public launchBlock;
  uint public lastLiquidityBurn;
  uint public constant liquidityBurnInterval = 24 hours;

  bool private inSwap = false;
  bool private swapEnabled = false;

  event MaxTxAmountUpdated(uint _maxTxAmount);

  modifier lockTheSwap {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor (
    address marketingWallet
  ) {
    _marketingWallet = payable(marketingWallet);
    _balances[_msgSender()] = _totalSupply;

    _isExcludedFromFee[_msgSender()] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[_marketingWallet] = true;
    _isExcludedFromFee[_deadAddress] = true;

    emit Transfer(address(0), _msgSender(), _totalSupply);
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
    return _totalSupply;
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
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    uint taxAmount;

    if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
      require (tradingOpen, "Trading is not enabled yet");

      if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
        require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
        require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
      }

      taxAmount = amount.mul((block.number > launchBlock + _reduceBuyTaxAfter) ? _finalBuyTax : _initialBuyTax).div(10000);
      if (to == uniswapV2Pair && from != address(this)) {
        require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
        taxAmount = amount.mul((block.number > launchBlock + _reduceSellTaxAfter) ? _finalSellTax : _initialSellTax).div(10000);
      }

      uint contractTokenBalance = balanceOf(address(this));
      if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _swapThreshold && block.number > launchBlock + _preventSwapBefore) {
        uint tokenAmount = min(amount, min(contractTokenBalance, _swapThreshold));
        if (tokenAmount > 0) {
          tokenAmount = tokenAmount.div(2);
          swapTokensForEth(tokenAmount);
          
          uint contractETHBalance = address(this).balance;
          if (contractETHBalance > 0) {
            addLiquidity(address(this).balance, tokenAmount);
          }
        }
      }
    }

    if (taxAmount > 0) {
      _balances[address(this)] = _balances[address(this)].add(taxAmount);
      emit Transfer(from, address(this), taxAmount);
    }

    _balances[from] = _balances[from].sub(amount);
    _balances[to] = _balances[to].add(amount.sub(taxAmount));

    emit Transfer(from, to, amount.sub(taxAmount));
  }

  function min(uint a, uint b) private pure returns (uint) {
    return (a > b) ? b : a;
  }

  function swapTokensForEth(uint tokenAmount) private lockTheSwap {
    if (tokenAmount == 0) return;
    if (!tradingOpen) return;

    tokenAmount = tokenAmount / 2;

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

  function addLiquidity(uint ethAmount, uint tokenAmount) private lockTheSwap {
    if (ethAmount == 0 || tokenAmount == 0) return;
    if (!tradingOpen) return;

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  function _burnLiquidity() private lockTheSwap {
    if (!tradingOpen) return;

    if (lastLiquidityBurn.add(liquidityBurnInterval) <= block.timestamp) {
      uint balance = IERC20(uniswapV2Pair).balanceOf(address(this));
      if (balance > 0) {
        balance = balance.div(20); // 5%

        uint tokenBalanceBefore = balanceOf(address(this));

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), balance);
        uint ethAmount = uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
          address(this), 
          balance, 
          0, 
          0, 
          address(this), 
          block.timestamp
        );

        uint deltaBalance = balanceOf(address(this)).sub(tokenBalanceBefore);

        _balances[address(this)] = _balances[address(this)].sub(deltaBalance);
        _balances[_deadAddress] = _balances[_deadAddress].add(deltaBalance);
        emit Transfer(address(this), _deadAddress, deltaBalance);

        Address.sendValue(_marketingWallet, ethAmount);

        lastLiquidityBurn = block.timestamp;
      }
    }
  }

  function openTrading() external payable onlyOwner {
    require(!tradingOpen, "Trading is already open");
    require(balanceOf(_msgSender()) > 0, "No token balance");
    require(msg.value > 0, "No eth value");

    uint tokenAmount = balanceOf(_msgSender());

    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    _approve(_msgSender(), address(this), tokenAmount);
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    _transfer(_msgSender(), address(this), tokenAmount);

    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    uniswapV2Router.addLiquidityETH{value: msg.value}(
      address(this),
      tokenAmount,
      0,
      0,
      _msgSender(),
      block.timestamp
    );

    swapEnabled = true;
    tradingOpen = true;
    launchBlock = block.number;
    lastLiquidityBurn = block.timestamp;
  }

  function burnLiquidity() external {
    _burnLiquidity();
  }

  function distribute(address[] calldata recipients, uint[] calldata amounts) external onlyOwner {
    require(recipients.length == amounts.length, "Error in arrays!");
    for (uint256 i = 0; i < recipients.length; i++) {
      _transfer(_msgSender(), recipients[i], amounts[i] * 10 ** _decimals);
    }
  }

  function rescueETH() external {
    require(_msgSender() == _marketingWallet, "Not authorized");
    payable(_msgSender()).sendValue(address(this).balance);
  }
 
  function rescueTokens(address _token) external {
    require(_msgSender() == _marketingWallet, "Not authorized");
    require(_token != address(this), "Can not rescue own token!");
    IERC20(_token).transfer(_msgSender(), IERC20(_token).balanceOf(address(this)));
  }

  receive() external payable {}
}