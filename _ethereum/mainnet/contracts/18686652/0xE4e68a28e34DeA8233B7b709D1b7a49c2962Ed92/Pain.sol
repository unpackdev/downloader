/**
    Pain Harold Token
    Because in crypto, we trust, and in memes, we invest! Our job is to turn your $PAIN into GAIN!

    Website: https://pain.rocks
    Telegram: https://t.me/painharoldeth
    X: https://x.com/painharoldeth
**/

// SPDX-License-Identifier: No License

pragma solidity 0.8.21;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract Pain is ERC20, Ownable {

  IUniswapV2Router02 public immutable uniswapV2Router;
  address public immutable uniswapV2Pair;

  uint256 public constant MAX_SUPPLY = 21_000_000_000e18;

  bool private swapping;

  address public marketingWallet;
  address public lpTokensReceiver;

  uint256 public swapTokensAtAmount = (MAX_SUPPLY * 5) / 10000; // 0.05%
  uint256 public maxWallet = (MAX_SUPPLY * 5) / 10000; // 0.05%

  bool public limitsInEffect = true;

  uint256 public constant taxRate = 2; // 2% of buy and sell

  /******************/

  // exclude from fees and max transaction amount
  mapping(address => bool) private _isExcludedFromFees;
  mapping(address => bool) public _excludedFromAntiWhale;

  // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
  // could be subject to a maximum transfer amount
  mapping(address => bool) public automatedMarketMakerPairs;

  event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
  event ExcludeFromFees(address indexed account, bool isExcluded);
  event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
  event revShareWalletUpdated(address indexed newWallet, address indexed oldWallet);
  event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);
  event lpTokensReceiverUpdated(address indexed newWallet, address indexed oldWallet);
  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);
  event ExcludedFromAntiWhale(address indexed account, bool excluded);

  constructor(address marWallet) ERC20('Pain Harold', 'PAIN') {

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uniswapV2Router = _uniswapV2Router;

    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

    marketingWallet = marWallet;
    lpTokensReceiver = owner();

    // exclude from paying fees or having max transaction amount
    excludeFromFees(owner(), true);
    excludeFromFees(address(this), true);

    _excludedFromAntiWhale[address(_uniswapV2Router)] = true;
    _excludedFromAntiWhale[address(uniswapV2Pair)] = true;
    _excludedFromAntiWhale[owner()] = true;
    _excludedFromAntiWhale[address(this)] = true;

    /*
        _mint is an internal function in ERC20.sol that is only called here,
        and CANNOT be called ever again
    */
    _mint(msg.sender, MAX_SUPPLY);
  }

  receive() external payable {}

  // remove limits after token is stable
  function removeLimits() external onlyOwner {
    limitsInEffect = false;
  }

  function setIsExcludedFromAntiWhale(address account, bool excluded) external onlyOwner {
      _excludedFromAntiWhale[account] = excluded;
      emit ExcludedFromAntiWhale(account, excluded);
  }

  function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
    require(newNum >= ((totalSupply() * 5) / 10000) / 1e18, 'Cannot set maxWallet lower than 0.05%');
    maxWallet = newNum * 1e18;
  }

  function excludeFromFees(address account, bool excluded) public onlyOwner {
    _isExcludedFromFees[account] = excluded;
    emit ExcludeFromFees(account, excluded);
  }

  function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
    require(pair != uniswapV2Pair, 'The pair cannot be removed from automatedMarketMakerPairs');

    _setAutomatedMarketMakerPair(pair, value);
  }

  function _setAutomatedMarketMakerPair(address pair, bool value) private {
    automatedMarketMakerPairs[pair] = value;

    emit SetAutomatedMarketMakerPair(pair, value);
  }

  function updateMarketingWallet(address newWallet) external onlyOwner {
    emit marketingWalletUpdated(newWallet, marketingWallet);
    marketingWallet = newWallet;
  }

  function setLpTokensReceiver(address newWallet) public onlyOwner {
    emit lpTokensReceiverUpdated(newWallet, lpTokensReceiver);
    lpTokensReceiver = newWallet;
  }

  function isExcludedFromFees(address account) public view returns (bool) {
    return _isExcludedFromFees[account];
  }


  function _transfer(address from, address to, uint256 amount) internal override {
    require(from != address(0), 'TOKEN: transfer from the zero address');
    require(to != address(0), 'TOKEN: transfer to the zero address');

    if (amount == 0) {
      super._transfer(from, to, 0);
      return;
    }

    if (limitsInEffect) {
      if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {

        //when buy
        if (automatedMarketMakerPairs[from] && !_excludedFromAntiWhale[to]) {
          require(amount + balanceOf(to) <= maxWallet, 'Max wallet exceeded');
        }
        //when sell
        else if (automatedMarketMakerPairs[to] && !_excludedFromAntiWhale[from]) {
        // When transfer
        } else if (!_excludedFromAntiWhale[to]) {
          require(amount + balanceOf(to) <= maxWallet, 'Max wallet exceeded');
        }
      }
    }

    uint256 contractTokenBalance = balanceOf(address(this));

    bool canSwap = contractTokenBalance >= swapTokensAtAmount;

    if (
      canSwap &&
      !swapping &&
      !automatedMarketMakerPairs[from] &&
      !_isExcludedFromFees[from] &&
      !_isExcludedFromFees[to]
    ) {
      swapping = true;

      swapBack();

      swapping = false;
    }

    bool takeFee = !swapping;

    // if any account belongs to _isExcludedFromFee account then remove the fee
    if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
      takeFee = false;
    }


    // only take fees on buys/sells, do not take on wallet transfers
    if (takeFee) {
      uint256 fees = 0;
      // on sell
      if (automatedMarketMakerPairs[to] && taxRate > 0) {
        fees = (amount * taxRate) / 100;
      }
      // on buy
      else if (automatedMarketMakerPairs[from] && taxRate > 0) {
        fees = (amount * taxRate) / 100;
      }

      if (fees > 0) {
        super._transfer(from, address(this), fees);
      }

      amount -= fees;
    }

    super._transfer(from, to, amount);
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
      address(this),
      block.timestamp
    );
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
      lpTokensReceiver,
      block.timestamp
    );
  }

  function swapBack() private {
    uint256 contractBalance = balanceOf(address(this));
    bool success;

    if (contractBalance == 0) {
      return;
    }

    if (contractBalance > swapTokensAtAmount * 20) {
      contractBalance = swapTokensAtAmount * 20;
    }

    // Halve the amount of liquidity tokens. 1/4 of tokens will remain for LP
    uint256 liquidityTokens = contractBalance / 4; 
    uint256 amountToSwapForETH = contractBalance - liquidityTokens;

    uint256 initialETHBalance = address(this).balance;

    swapTokensForEth(amountToSwapForETH);

    uint256 ethBalance = address(this).balance - initialETHBalance;

    // 1/3 of converted tokens to eth will be used for liquidity
    uint256 ethForLiquidity = ethBalance / 3;

    if (liquidityTokens > 0 && ethForLiquidity > 0) {
      addLiquidity(liquidityTokens, ethForLiquidity);
      emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
    }

    (success, ) = address(marketingWallet).call{ value: address(this).balance }('');
  }

  function withdrawStuckToken(address _token, address _to) external onlyOwner {
    require(_token != address(0), '_token address cannot be 0');
    uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(_to, _contractBalance);
  }

  function withdrawStuckEth(address toAddr) external onlyOwner {
    (bool success, ) = toAddr.call{ value: address(this).balance }('');
    require(success);
  }

}
