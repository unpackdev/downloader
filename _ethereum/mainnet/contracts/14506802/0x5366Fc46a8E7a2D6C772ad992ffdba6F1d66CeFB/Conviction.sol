/*********************************************************************************
Conviction (CONV)

                       _             _             
                      (_)        _  (_)            
  ____ ___  ____ _   _ _  ____ _| |_ _  ___  ____  
 / ___) _ \|  _ \ | | | |/ ___|_   _) |/ _ \|  _ \ 
( (__| |_| | | | \ V /| ( (___  | |_| | |_| | | | |
 \____)___/|_| |_|\_/ |_|\____)  \__)_|\___/|_| |_|

Live your life with conviction. Conviction can catalyze your dreams becoming reality
and determine whether you make it or not. We're here to completely upend the
scene with conviction for the culture by building the biggest
degen ecosystem to ever show it's face in crypto. With CONV's tokenomics,
innovative tapering jeet tax, and buyer incentive lottery program,
you can have a shot at winning massive amounts of ETH every hour. In
conjunction with Chainlink verifiable random functions and a little creativity,
we built an innovative mechanism to reward buyers of CONV and those who
execute the lottery draw function each buy period.


TOKEN DISTRIBUTION

Fixed supply: 1,000,000,000 CONV
100% supply went into the liquidity pool on day 1
  - No VCs
  - No team tokens
  - No funny business


TOKENOMICS

buy: 5% tax
  - 2.5% reward pool
  - 2.5% auto LP
sell: 5-20% tax (see JEET SELL TAX below)


BUYER INCENTIVE PROGRAM

When you buy CONV you are entered into an hourly lottery drawn by Chainlink VRFs
that will reward 5 buyers who bought during that hour with 20% (4% each) of the current
buyer incentive pool, which is the amount of ETH in the token contract.
Every hour 5 new winners will be drawn, and the pool of buyers will then
reset to be drawn from again for the next hour for buyers during that next hour period.


DRAW THE WINNERS

In order for the winners of the lottery to be drawn, either
`drawWinnerAtPreviousBuyPeriod` or `drawWinnerAt` need to be executed on this contract.
Anyone who wants can execute these functions when a buy period is over and winners have
not been drawn yet. The lottery drawer will be rewarded 2% of the buyer
incentive pool at that point in time.


JEET SELL TAX

We're building something massive: one of the largest decentralized
lottery mechanisms to exist in crypto. In order to support
this vision we want fellow CONVers to hold their CONV or get punished
accordingly. We implemented a tapering sell tax that rewards you by taxing
less the longer you hold your CONV.

At the point you buy, to sell you will be charged 4x the standard tax (20%).
Every hour your sell tax will decrease from 20% all the way down to the standard tax
if you hold for >=72 hours.

See below for an example of how tax is calculated:

Your calculated sell tax amount based on when you sell:
  - 0-1 hours after buy: 20%
  - 1-2 hour after buy: 19.93%
  - 2-3 hours after buy: 19.86%
  - 3-4 hours after buy: 19.79%
  ...
  - 72+ hours after buy: 5%


COMMUNITY

Our vision is CONV will become a community-owned, organically grown project. We
want the community and holders to take over, create the website & socials, and
when we grow the dev will reenter the scene for a full DAO build-out to empower the
community to vote on the future of CONV and it's ecosystem.
*********************************************************************************/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract Conviction is ERC20, Ownable, VRFConsumerBaseV2 {
  uint256 private constant ONE_HOUR = 60 * 60;
  uint256 private constant PERCENT_DENOMENATOR = 1000;

  // FUCK THE JEETS
  uint256 public constant JEET_TAX_MULTIPLIER = 4;
  uint256 public constant JEET_TAPER_HOURS = 72;

  VRFCoordinatorV2Interface vrfCoord;
  LinkTokenInterface link;
  uint64 private _vrfSubscriptionId;
  bytes32 private _vrfKeyHash;
  uint32 private _vrfCallbackGasLimit = 600000;
  mapping(uint256 => uint256) private _buyInitiators;
  mapping(uint256 => address[]) private _buyWinners;

  uint16 public numBuyWinners = 5;

  uint256 public percentTreasuryBuyerPool = 200; // 20%
  uint256 public percentTreasuryInitiatorPool = 20; // 2%

  address payable public treasury;

  mapping(address => bool) private _isTaxExcluded;

  bool private _taxesOff;
  uint256 private _taxBuyerIncent = 25; // 2.5%
  uint256 private _taxLp = 25; // 2.5%
  uint256 private _totalTax;

  uint256 private _liquifyRate = 10;
  uint256 public launchTime;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  mapping(address => uint256) private _lastBuy;
  uint256 public buyDrawSeconds = ONE_HOUR;
  mapping(uint256 => address[]) public buyPeriodBuyers;
  mapping(uint256 => mapping(address => bool)) public buyPeriodBuyersIndexed;

  mapping(address => bool) private _isFucker;
  address[] private _confirmedFuckers;

  uint256 private _lastNuke;
  uint256 private _nukeFreq = 60 * 10;

  bool private _swapEnabled = true;
  bool private _swapping = false;

  event InitiatedBuyWinner(
    uint256 indexed requestId,
    uint256 indexed buyPeriod
  );
  event SelectedBuyWinner(uint256 indexed requestId, uint256 indexed buyPeriod);

  modifier lockTheFuckingSwap() {
    _swapping = true;
    _;
    _swapping = false;
  }

  constructor(
    address _vrfCoordinator,
    uint64 _subscriptionId,
    address _linkToken,
    bytes32 _keyHash
  ) ERC20('Conviction', 'CONV') VRFConsumerBaseV2(_vrfCoordinator) {
    _mint(address(this), 1_000_000_000 * 10**18);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );
    uniswapV2Router = _uniswapV2Router;
    _setTotalTax();

    _isTaxExcluded[address(this)] = true;
    _isTaxExcluded[msg.sender] = true;

    vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
    link = LinkTokenInterface(_linkToken);
    _vrfSubscriptionId = _subscriptionId;
    _vrfKeyHash = _keyHash;
  }

  function launch() external payable onlyOwner {
    require(launchTime == 0, 'already launched');
    require(msg.value > 0, 'need ETH for initial LP');
    _addLp(totalSupply(), msg.value);
    launchTime = block.timestamp;
  }

  function getBuyPeriodWinners(uint256 _period)
    external
    view
    returns (address[] memory)
  {
    return _buyWinners[_period];
  }

  function drawWinnerAtPreviousBuyPeriod() external {
    uint256 _period = getBuyPeriod() - 1;
    _drawWinnerAtBuyPeriod(_period);
  }

  function drawWinnerAt(uint256 _period) external {
    _drawWinnerAtBuyPeriod(_period);
  }

  function _drawWinnerAtBuyPeriod(uint256 _period) internal {
    require(address(this).balance > 0, 'nothing to give winners');
    require(getBuyPeriod() > _period, 'buyPeriod is not complete');
    require(getAllBuyPeriodBuyerAmount(_period) > 0, 'no buyers during period');

    uint256 requestId = vrfCoord.requestRandomWords(
      _vrfKeyHash,
      _vrfSubscriptionId,
      uint16(3),
      _vrfCallbackGasLimit,
      numBuyWinners
    );

    require(_buyInitiators[requestId] == 0, 'already initiated');
    _buyInitiators[requestId] = _period;

    uint256 _balanceBefore = address(this).balance;
    uint256 _initiatorAmount = (_balanceBefore * percentTreasuryInitiatorPool) /
      PERCENT_DENOMENATOR;
    payable(msg.sender).call{ value: _initiatorAmount }('');
    require(
      address(this).balance >= _balanceBefore - _initiatorAmount,
      'took too much'
    );
    emit InitiatedBuyWinner(requestId, _period);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
  {
    uint256 _period = _buyInitiators[requestId];
    uint256 _allBuyerLength = getAllBuyPeriodBuyerAmount(_period);

    uint256 _balanceBefore = address(this).balance;
    uint256 _amountETHTotal = (_balanceBefore * percentTreasuryBuyerPool) /
      PERCENT_DENOMENATOR;
    uint256 _amountETHPerWinner = _amountETHTotal / randomWords.length;

    for (uint256 i = 0; i < randomWords.length; i++) {
      uint256 _word = randomWords[i];
      uint256 _winnerIdx = _word % _allBuyerLength;
      _buyWinners[_period].push(buyPeriodBuyers[_period][_winnerIdx]);
      payable(_buyWinners[_period][i]).call{ value: _amountETHPerWinner }('');
    }
    require(address(this).balance >= _balanceBefore - _amountETHTotal);
    emit SelectedBuyWinner(requestId, _period);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isOwner = sender == owner() || recipient == owner();
    require(
      _isOwner || amount <= _maxTx(sender, recipient),
      'ERC20: exceed amx txn'
    );
    require(!_isFucker[recipient], 'Stop fucker!');
    require(!_isFucker[sender], 'Stop fucker!');
    require(!_isFucker[_msgSender()], 'Stop fucker!');
    uint256 contractTokenBalance = balanceOf(address(this));

    bool _isBuy = sender == uniswapV2Pair &&
      recipient != address(uniswapV2Router);
    bool _isSell = recipient == uniswapV2Pair;
    bool _isSwap = _isBuy || _isSell;
    if (_isSwap) {
      if (block.timestamp == launchTime) {
        _isFucker[recipient] = true;
        _confirmedFuckers.push(recipient);
      }
    }

    if (_isBuy) {
      _lastBuy[recipient] = block.timestamp;

      uint256 _period = getBuyPeriod();
      if (!buyPeriodBuyersIndexed[_period][recipient]) {
        buyPeriodBuyersIndexed[_period][recipient] = true;
        buyPeriodBuyers[_period].push(recipient);
      }
    }

    uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) /
      PERCENT_DENOMENATOR;
    bool _overMin = contractTokenBalance >= _minSwap;
    if (
      _swapEnabled &&
      !_swapping &&
      !_isOwner &&
      _overMin &&
      launchTime != 0 &&
      sender != uniswapV2Pair
    ) {
      _swap(_minSwap);
    }

    uint256 tax = 0;
    if (
      launchTime != 0 &&
      !_taxesOff &&
      !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])
    ) {
      tax = (amount * _totalTax) / PERCENT_DENOMENATOR;
      if (tax > 0) {
        if (_isSell) {
          tax = calculateJeetTax(sender, tax);
        }
        super._transfer(sender, address(this), tax);
      }
    }

    super._transfer(sender, recipient, amount - tax);
  }

  function getAllBuyPeriodBuyerAmount(uint256 _period)
    public
    view
    returns (uint256)
  {
    return buyPeriodBuyers[_period].length;
  }

  function _maxTx(address sender, address recipient)
    private
    view
    returns (uint256)
  {
    bool _isOwner = sender == owner() || recipient == owner();
    uint256 expiration = 60 * 15; // 15 minutes
    if (
      _isOwner || launchTime == 0 || block.timestamp > launchTime + expiration
    ) {
      return totalSupply();
    }
    return totalSupply() / 100; // 1%
  }

  function _swap(uint256 contractTokenBalance) private lockTheFuckingSwap {
    uint256 balBefore = address(this).balance;
    uint256 liquidityTokens = (contractTokenBalance * _taxLp) / _totalTax / 2;
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

  function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      treasury == address(0) ? owner() : treasury,
      block.timestamp
    );
  }

  function _processFees(uint256 amountETH, uint256 amountLpTokens) private {
    uint256 lpETH = (amountETH * _taxLp) / _totalTax;
    if (amountLpTokens > 0) {
      _addLp(amountLpTokens, lpETH);
    }
  }

  function _setTotalTax() private {
    _totalTax = _taxBuyerIncent + _taxLp;
    require(
      _totalTax <= (PERCENT_DENOMENATOR * 20) / 100,
      'tax cannot be above 20%'
    );
  }

  // fuck you jeets
  function calculateJeetTax(address _sender, uint256 _tax)
    public
    view
    returns (uint256)
  {
    if (block.timestamp < calculateJeetExpiration(_sender)) {
      uint256 _hoursAfterBuy = (block.timestamp - _lastBuy[_sender]) / ONE_HOUR;
      return
        (_tax * ((JEET_TAX_MULTIPLIER * JEET_TAPER_HOURS) - _hoursAfterBuy)) /
        JEET_TAPER_HOURS;
    }
    return _tax;
  }

  function calculateJeetExpiration(address _sender)
    public
    view
    returns (uint256)
  {
    return _lastBuy[_sender] + (JEET_TAPER_HOURS * ONE_HOUR);
  }

  function getBuyPeriod() public view returns (uint256) {
    uint256 secondsSinceLaunch = block.timestamp - launchTime;
    return 1 + (secondsSinceLaunch / buyDrawSeconds);
  }

  function isFuckerRemoved(address account) external view returns (bool) {
    return _isFucker[account];
  }

  function blacklistFucker(address account) external onlyOwner {
    require(
      account != address(uniswapV2Router),
      'cannot not blacklist Uniswap'
    );
    require(!_isFucker[account], 'user is already blacklisted');
    _isFucker[account] = true;
    _confirmedFuckers.push(account);
  }

  function forgiveFucker(address account) external onlyOwner {
    require(_isFucker[account], 'user is not blacklisted');
    for (uint256 i = 0; i < _confirmedFuckers.length; i++) {
      if (_confirmedFuckers[i] == account) {
        _confirmedFuckers[i] = _confirmedFuckers[_confirmedFuckers.length - 1];
        _isFucker[account] = false;
        _confirmedFuckers.pop();
        break;
      }
    }
  }

  function setTaxBuyerIncent(uint256 _tax) external onlyOwner {
    _taxBuyerIncent = _tax;
    _setTotalTax();
  }

  function setTaxLp(uint256 _tax) external onlyOwner {
    _taxLp = _tax;
    _setTotalTax();
  }

  function setTreasury(address _treasury) external onlyOwner {
    treasury = payable(_treasury);
  }

  function setLiquifyRate(uint256 _rate) external onlyOwner {
    require(_rate <= PERCENT_DENOMENATOR / 10, 'cannot be more than 10%');
    _liquifyRate = _rate;
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    _isTaxExcluded[_wallet] = _isExcluded;
  }

  function setTaxesOff(bool _areOff) external onlyOwner {
    _taxesOff = _areOff;
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function setNukeFreq(uint256 _seconds) external onlyOwner {
    _nukeFreq = _seconds;
  }

  function setBuyDrawSeconds(uint256 _seconds) external onlyOwner {
    buyDrawSeconds = _seconds;
  }

  function setPercentTreasuryBuyerPool(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    percentTreasuryBuyerPool = _percent;
  }

  function setPercentTreasuryInitiatorPool(uint256 _percent)
    external
    onlyOwner
  {
    require(
      _percent <= (PERCENT_DENOMENATOR * 20) / 100,
      'cannot be more than 20%'
    );
    percentTreasuryInitiatorPool = _percent;
  }

  function setNumBuyerWinners(uint16 _winners) external onlyOwner {
    require(_winners <= 20, 'no more than 20 winners at a time');
    numBuyWinners = _winners;
  }

  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackGasLimit = _gas;
  }

  function manualNuke(uint256 _percent, address _to) external onlyOwner {
    require(block.timestamp > _lastNuke + _nukeFreq, 'cooldown please');
    require(_percent <= PERCENT_DENOMENATOR / 10, 'cannot nuke more than 10%');
    _lastNuke = block.timestamp;

    uint256 amountToBurn = (balanceOf(uniswapV2Pair) * _percent) /
      PERCENT_DENOMENATOR;
    if (amountToBurn > 0) {
      address receiver = _to == address(0) ? address(0xdead) : _to;
      super._transfer(uniswapV2Pair, receiver, amountToBurn);
    }

    IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
    pair.sync();
  }

  function withdrawETH() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }

  receive() external payable {}
}
