/**
thehelper.eth presents: The Project Helper Edition

FIRST UP WE HAVE: Marshall Rogan Inu [MRI] -- Because they're ACTUALLY helping people as we speak

We're here to give a boost to your favorite project.
No website, no telegram, none of the bullshit. Let's run it up.
Completely renounced, all LP burned, nothing but something to help good projects.

Project deployer addresses, keep an eye out for on-chain messages if you want alpha that you might be coming up.

If you have suggestions, we'll be lurking CT or you can send thehelper.eth a message on-chain.

*********************************************************************************
*********************************** WARNING *************************************
THERE WILL BE COPYCATS. If the deployer is not thehelper.eth, it's not real.
*********************************************************************************

What is this?
  - We launch, provide LP and burn it, and renounce immediately
  - You ape and your favorite token starts getting 🔥burned alive🔥

NOTE: There will be a 2% supply transaction max for the first hour after launch only,
after that, no max.

Tokenomics (8%, 8-11% slippage [you know, price impact and such]):
  - always:
    * 1% provided back to LP

  - FIRST 7 DAYS AFTER LAUNCH:
    * 4% buyback and burn of your favorite token
    * 3% dev
  - forever after that:
    * 7% buyback and burn of your favorite token
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract TheHelper is Context, IERC20, IERC20Metadata, Ownable {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  address public burningAlive = 0x0913dDAE242839f8995c0375493f9a1A3Bddc977;

  uint8 private _decimals = 9;
  uint256 private _totalSupply;

  string private _name = 'thMarshall Rogan Inu';
  string private _symbol = 'thMRI';
  address private constant DEAD = address(0xdead);
  uint256 private constant _totalTax = 8; // 8%

  uint256 private launchTime;

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;

  bool weSwappin = false;

  modifier lockItUp() {
    weSwappin = true;
    _;
    weSwappin = false;
  }

  constructor() {
    _mint(address(this), 69_696_969_696 * 10**_decimals);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );
    uniswapV2Router = _uniswapV2Router;
  }

  function launch() external payable onlyOwner {
    require(msg.value > 0, 'dolla bills for LP');
    _addLpAndBurnAlive(_totalSupply, msg.value);
    renounceOwnership();
    launchTime = block.timestamp;
  }

  function _addLpAndBurnAlive(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      DEAD,
      block.timestamp
    );
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    virtual
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
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      'ERC20: transfer amount exceeds allowance'
    );
    unchecked {
      _approve(sender, _msgSender(), currentAllowance - amount);
    }

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      'ERC20: decreased allowance below zero'
    );
    unchecked {
      _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');

    if (launchTime > 0) {
      require(amount <= _maxTx(), 'ERC20: too much ser');
      uint256 contractTokenBalance = balanceOf(address(this));

      // don't allow swapping more than 0.5%
      uint256 maxToSwap = _maxTx() > _totalSupply / 200
        ? _totalSupply / 100
        : _maxTx();
      if (contractTokenBalance >= maxToSwap) {
        contractTokenBalance = maxToSwap;
      }

      bool overMin = contractTokenBalance >= _totalSupply / 5000;
      if (!weSwappin && overMin && sender != uniswapV2Pair) {
        _doTheMfSwap(contractTokenBalance);
      }
    }

    unchecked {
      _balances[sender] = senderBalance - amount;
    }

    uint256 tax = launchTime == 0 ? 0 : (amount * _totalTax) / 100;
    _balances[recipient] += amount - tax;
    _balances[address(this)] += tax;

    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _maxTx() private view returns (uint256) {
    uint256 oneHour = 60 * 60;
    if (block.timestamp > launchTime + oneHour) {
      return _totalSupply;
    }
    return _totalSupply / 50; // 2%
  }

  function _doTheMfSwap(uint256 contractTokenBalance) private lockItUp {
    uint256 balBefore = address(this).balance;
    (, , uint256 lp, ) = _getTaxes();
    uint256 liquidityTokens = (contractTokenBalance * lp) / _totalTax / 2;
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
    if (balToProcess > 0) {
      _processFees(balToProcess, liquidityTokens);
    }
  }

  function _buybackAndBurnAlive(uint256 amount) private {
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = burningAlive;

    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
      value: amount
    }(0, path, DEAD, block.timestamp);
  }

  function _processFees(uint256 amountETH, uint256 amountLpTokens) private {
    (uint256 bb, uint256 dev, , ) = _getTaxes();

    uint256 bbETH = (amountETH * bb) / _totalTax;
    uint256 devETH = (amountETH * dev) / _totalTax;
    uint256 lpETH = amountETH - bbETH - devETH;

    _buybackAndBurnAlive(bbETH);
    _addLpAndBurnAlive(amountLpTokens, lpETH);
    if (dev > 0) {
      address devWallet = 0xe51922C7a4A4bfDdD8Ed6303bdB35c989e14a699;
      (bool success, ) = payable(devWallet).call{ value: devETH }('');
    }
  }

  function _getTaxes()
    private
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 bb = 7;
    uint256 dev = 0;
    uint256 lp = 1;

    uint256 sevenDays = 60 * 60 * 24 * 7;
    bool dexExists = block.timestamp < launchTime + sevenDays;
    if (dexExists) {
      bb = 4;
      dev = 3;
    }
    return (bb, dev, lp, _totalTax);
  }

  receive() external payable {}
}
