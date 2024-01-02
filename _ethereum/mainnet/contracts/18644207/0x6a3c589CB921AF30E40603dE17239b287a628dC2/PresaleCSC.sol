/*
   _____                  _        _____                  _____      _
  / ____|                | |      / ____|                / ____|    (_)
 | |     _ __ _   _ _ __ | |_ ___| (___   ___ __ _ _ __ | |     ___  _ _ __
 | |    | '__| | | | '_ \| __/ _ \\___ \ / __/ _` | '_ \| |    / _ \| | '_ \
 | |____| |  | |_| | |_) | || (_) |___) | (_| (_| | | | | |___| (_) | | | | |
  \_____|_|   \__, | .__/ \__\___/_____/ \___\__,_|_| |_|\_____\___/|_|_| |_|
  _____        __/ | |      _
 |  __ \      |___/|_|     | |
 | |__) | __ ___  ___  __ _| | ___
 |  ___/ '__/ _ \/ __|/ _` | |/ _ \
 | |   | | |  __/\__ \ (_| | |  __/
 |_|   |_|  \___||___/\__,_|_|\___|

*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.20;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

import "./IUniswapV2Router02.sol";

import "./ICryptoScanCoin.sol";
import "./IPresaleCSC.sol";
import "./IPriceFeed.sol";

uint256 constant _1_WEEK = 7 days;
uint256 constant _2_WEEKS = 2 * _1_WEEK;
uint256 constant _3_WEEKS = 3 * _1_WEEK;
uint256 constant _1_MONTH = 30 days;
uint256 constant _2_MONTHS = 2 * _1_MONTH;
uint256 constant _3_MONTHS = 3 * _1_MONTH;
uint256 constant _4_MONTHS = 4 * _1_MONTH;

uint256 constant UNLOCK_PERCENT_BEFORE_1_MONTH = 10;
uint256 constant UNLOCK_PERCENT_BEFORE_2_MONTHS = 25;
uint256 constant UNLOCK_PERCENT_BEFORE_3_MONTHS = 45;
uint256 constant UNLOCK_PERCENT_BEFORE_4_MONTHS = 70;

contract PresaleCSC is IPresaleCSC, ReentrancyGuard, Ownable {

    uint256 public constant DEFAULT_PHASE_INTERVAL = _3_WEEKS;

    // SAFETY_GO_PUBLIC_OFFSET should be less than SAFETY_VESTING_START_TIME_OFFSET
    uint256 public constant SAFETY_GO_PUBLIC_OFFSET = _1_WEEK;
    uint256 public constant SAFETY_VESTING_START_TIME_OFFSET = _2_WEEKS;

    uint256 public constant MOST_COMMON_DECIMALS = 18;

    uint256 public constant CSC_TOKEN_DECIMALS = 18;
    uint256 public constant PRICE_FEED_USD_DECIMALS = 8;
    uint256 public constant USD_DECIMALS = MOST_COMMON_DECIMALS;
    uint256 public constant USDT_TOKEN_DECIMALS = 6;
    uint256 public constant ETH_TOKEN_DECIMALS = 18;

    uint256 public constant CSC = 10 ** CSC_TOKEN_DECIMALS;
    uint256 public constant TENTH_OF_A_CENT = 10 ** (USD_DECIMALS - 3);
    uint256 public constant USD = 1000 * TENTH_OF_A_CENT;
    uint256 public constant USDT = 10 ** USDT_TOKEN_DECIMALS;
    uint256 public constant ETH = 10 ** ETH_TOKEN_DECIMALS;

    uint256 public constant NUMBER_OF_CSC_TOKENS_FOR_EXCHANGE = 75_000_000;

    uint256 public constant INITIAL_MAX_TOKENS_TO_BUY = 3_000_000;
    uint256 public constant INITIAL_MIN_TOKENS_TO_BUY = 300;

    uint256 public constant NUMBER_OF_PHASES = 4;

    uint256 public constant LISTING_PRICE_IN_USD = 100 * TENTH_OF_A_CENT;

    uint256 public constant MINIMUM_DEX_PERCENTAGE = 50;
    uint256 public constant MAXIMUM_DEX_PERCENTAGE = 80;

    uint256[NUMBER_OF_PHASES] public TOKENS_TO_SELL_PER_PHASE = [
        12_500_000,
        25_000_000,
        37_500_000,
        50_000_000
    ];

    // WITHOUT decimals!
    uint256[NUMBER_OF_PHASES] public TOTAL_TOKENS_PER_PHASE = [
        TOKENS_TO_SELL_PER_PHASE[0],
        TOKENS_TO_SELL_PER_PHASE[0] + TOKENS_TO_SELL_PER_PHASE[1],
        TOKENS_TO_SELL_PER_PHASE[0] + TOKENS_TO_SELL_PER_PHASE[1] + TOKENS_TO_SELL_PER_PHASE[2],
        TOKENS_TO_SELL_PER_PHASE[0] + TOKENS_TO_SELL_PER_PHASE[1] + TOKENS_TO_SELL_PER_PHASE[2] + TOKENS_TO_SELL_PER_PHASE[3]
    ];

    // WITH decimals!
    uint256[NUMBER_OF_PHASES] public PRICES_PER_PHASE = [
        33 * TENTH_OF_A_CENT,
        40 * TENTH_OF_A_CENT,
        51 * TENTH_OF_A_CENT,
        72 * TENTH_OF_A_CENT
    ];

    address private immutable _treasuryWallet;

    uint256 private _totalTokensSold;
    uint256 private _startTime;

    uint256 private _maxTokensToBuy;
    uint256 private _minTokensToBuy;
    uint256 private _currentPhase;

    uint256[] private _phaseEndTimes;
    uint256[] private _soldTokensInPhase;

    uint256 private _checkPoint;
    uint256 private _usdRaised;

    uint256 private _ethReceived;
    uint256 private _usdtReceived;

    uint256 private _dexPercentage;

    IERC20 private immutable _usdtContract;

    IPriceFeed private immutable _priceFeedEthAggregator;
    IPriceFeed private immutable _priceFeedUsdtAggregator;

    mapping(address => uint256) private _cscAmountPurchased;

    uint256 private _vestingStartTime;

    ICryptoScanCoin private immutable _cscContract;
    IUniswapV2Router02 private immutable _uniswapV2Router;

    bool private _started;
    uint256 private immutable _deployTime;

    IUniswapV2Pair private _lpContract;
    uint256 private _lpTokensUnlockDate;

    event TokensBought(address indexed user, uint256 indexed tokensBought, address indexed purchaseToken, uint256 amountPaid, uint256 usdEq, uint256 timestamp);
    event MaxTokensUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);
    event MinTokensUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);

    constructor
    (
        address cscContractAddress,
        address treasuryWallet,
        address usdtAddress,
        address priceFeedEthAggregatorAddress,
        address priceFeedUsdtAggregatorAddress,
        address uniswapV2RouterAddress
    )
    Ownable(_msgSender())
    {
        require(cscContractAddress != address(0), "CSC contract cannot be null address");
        require(treasuryWallet != address(0), "Treasury wallet cannot be null address");
        require(usdtAddress != address(0), "Tether (USDT) contract cannot be null address");
        require(priceFeedEthAggregatorAddress != address(0), "Chainlink ETH/USD price feed aggregator contract cannot be null address");
        require(priceFeedUsdtAggregatorAddress != address(0), "Chainlink USDT/USD price feed aggregator contract cannot be null address");
        require(uniswapV2RouterAddress != address(0), "Uniswap V2 router contract cannot be null address");

        _cscContract = ICryptoScanCoin(cscContractAddress);

        _treasuryWallet = treasuryWallet;

        _started = false;
        _deployTime = block.timestamp;

        _totalTokensSold = 0;

        _startTime = type(uint256).max;
        _vestingStartTime = type(uint256).max;

        _maxTokensToBuy = INITIAL_MAX_TOKENS_TO_BUY;    // without decimals!
        _minTokensToBuy = INITIAL_MIN_TOKENS_TO_BUY;    // without decimals!

        _currentPhase = 0;

        for (uint i = 0; i < NUMBER_OF_PHASES; i++) {
            //_phaseEndTimes will be added at presale start
            _soldTokensInPhase.push(0);    // Number of CSC sold per phase
        }

        _checkPoint = 0;
        _usdRaised = 0 * USD;

        _ethReceived = 0 * ETH;
        _usdtReceived = 0 * USDT;

        _dexPercentage = MINIMUM_DEX_PERCENTAGE;

        _usdtContract = IERC20(usdtAddress);
        _priceFeedEthAggregator = IPriceFeed(priceFeedEthAggregatorAddress);
        _priceFeedUsdtAggregator = IPriceFeed(priceFeedUsdtAggregatorAddress);
        _uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);

        _lpContract = IUniswapV2Pair(address(0));
        _lpTokensUnlockDate = 0;
    }

    receive() external payable { }

    modifier checkSaleState(uint256 amount) {
        require(_started, "Sale not started yet");
        require(block.timestamp >= _startTime && block.timestamp <= getEndTime(), "Invalid time for buying");
        require(amount > 0, "Invalid sale amount");
        _;
    }

    function vestingStartTime() public view override returns (uint256) {
        return _vestingStartTime;
    }

    function isStarted() public view returns (bool) {
        return _started;
    }

    function isFinished() public view returns (bool) {
        bool endTimeGone = (block.timestamp > getEndTime());
        bool tokensGone = (_totalTokensSold == TOTAL_TOKENS_PER_PHASE[NUMBER_OF_PHASES - 1]);
        bool checkPointGone = (_checkPoint == TOTAL_TOKENS_PER_PHASE[NUMBER_OF_PHASES - 1]);
        return endTimeGone || tokensGone || checkPointGone;
    }

    function getDeployTime() public view returns (uint256) {
        return _deployTime;
    }

    function getLpTokenAddress() public view returns (address) {
        return address(_lpContract);
    }

    function getLpTokensUnlockDate() public view returns (uint256) {
        return _lpTokensUnlockDate;
    }

    function getEthReceived() public view returns (uint256) {
        return _ethReceived;
    }

    function getUsdtReceived() public view returns (uint256) {
        return _usdtReceived;
    }

    function getDexPercentage() public view returns (uint256) {
        return _dexPercentage;
    }

    function getSoldTokensInPhase(uint256 phase) public view returns (uint256) {
        return _soldTokensInPhase[phase];
    }

    function getSuccessRatePercent(uint256 phase) public view returns (uint256) {
        require(phase < _currentPhase || isFinished(), "Phase not finished yet");
        uint256 tokensSold = _soldTokensInPhase[phase];
        return (tokensSold * 100) / TOKENS_TO_SELL_PER_PHASE[phase];
    }

    function getMaxTokensToBuy() public view returns (uint256) {
        return _maxTokensToBuy;
    }

    function getMinTokensToBuy() public view returns (uint256) {
        return _minTokensToBuy;
    }

    function getCurrentPhase() public view returns (uint256) {
        return _currentPhase;
    }

    function getCheckPoint() public view returns (uint256) {
        return _checkPoint;
    }

    function getUsdRaised() public view returns (uint256) {
        return _usdRaised;
    }

    function getTotalTokensSold() public view returns (uint256) {
        return _totalTokensSold;
    }

    function getStartTime() public view returns (uint256) {
        return _startTime;
    }

    function getPhaseEndTime(uint256 phase) public view returns (uint256) {
        return _phaseEndTimes[phase];
    }

    function getEndTime() public view returns (uint256) {
        if (!_started) {
            return type(uint256).max;
        }
        return _phaseEndTimes[_currentPhase] + (NUMBER_OF_PHASES - _currentPhase - 1) * DEFAULT_PHASE_INTERVAL;
    }

    function getCscContractAddress() public view returns (address) {
        return address(_cscContract);
    }

    function getUsdtContractAddress() public view returns (address) {
        return address(_usdtContract);
    }

    function getUniswapV2RouterAddress() public view returns (address) {
        return address(_uniswapV2Router);
    }

    /**
     * @dev To get latest ETH price in 10 ** USD_DECIMALS format
     */
    function getLatestEtherPriceInUsd() public view returns (uint256) {
        (, int256 price, , , ) = _priceFeedEthAggregator.latestRoundData();
        return uint256(price) * (10 ** (USD_DECIMALS - PRICE_FEED_USD_DECIMALS));
    }

    /**
     * @dev To get latest USDT price in 10 ** USD_DECIMALS format
     */
    function getLatestTetherPriceInUsd() public view returns (uint256) {
        (, int256 price, , , ) = _priceFeedUsdtAggregator.latestRoundData();
        return uint256(price) * (10 ** (USD_DECIMALS - PRICE_FEED_USD_DECIMALS));
    }

    /**
     * @dev Helper funtion to get ETH price for given amount
     * @param amount No of tokens to buy
     */
    function ethBuyHelper(uint256 amount) public view returns (uint256 ethAmount) {
        uint256 usdPrice;
        (usdPrice,) = calculatePrice(amount);
        ethAmount = (usdPrice * ETH) / getLatestEtherPriceInUsd();
    }

    /**
     * @dev Helper funtion to get USDT price for given amount
     * @param amount No of tokens to buy
     */
    function usdtBuyHelper(uint256 amount) public view returns (uint256 usdtAmount) {
        uint256 usdPrice;
        (usdPrice,) = calculatePrice(amount);
        usdtAmount = (usdPrice * USDT) / getLatestTetherPriceInUsd();
    }

    function getLockedAmount(address buyer) public view override returns (uint256) {
        if (block.timestamp < _vestingStartTime) {
            return _cscAmountPurchased[buyer];
        }

        if (block.timestamp < (_vestingStartTime + _1_MONTH)) {
            return (_cscAmountPurchased[buyer] * (100 - UNLOCK_PERCENT_BEFORE_1_MONTH)) / 100;
        }

        if (block.timestamp < (_vestingStartTime + _2_MONTHS)) {
            return (_cscAmountPurchased[buyer] * (100 - UNLOCK_PERCENT_BEFORE_2_MONTHS)) / 100;
        }

        if (block.timestamp < (_vestingStartTime + _3_MONTHS)) {
            return (_cscAmountPurchased[buyer] * (100 - UNLOCK_PERCENT_BEFORE_3_MONTHS)) / 100;
        }

        if (block.timestamp < (_vestingStartTime + _4_MONTHS)) {
            return (_cscAmountPurchased[buyer] * (100 - UNLOCK_PERCENT_BEFORE_4_MONTHS)) / 100;
        }

        return 0;
    }

    function getInfo() public view returns
    (
        uint256 currentPhase,
        uint256 actPrice,
        uint256 nextPrice,
        uint256 actEndTime,
        uint256 totalUsdRaised,
        uint256 usdRaisedInThisPhase,
        uint256 usdToRaiseInThisPhase,
        uint256 usdToRaiseInNextPhase,
        uint256 etherPrice,
        uint256 tetherPrice,
        bool finished
    )
    {
        currentPhase = _currentPhase;
        actPrice = PRICES_PER_PHASE[_currentPhase];
        nextPrice = (_currentPhase == NUMBER_OF_PHASES - 1) ? actPrice : PRICES_PER_PHASE[_currentPhase + 1];
        actEndTime = _phaseEndTimes[_currentPhase];

        totalUsdRaised = _usdRaised;
        usdRaisedInThisPhase = _soldTokensInPhase[_currentPhase] * PRICES_PER_PHASE[_currentPhase];
        usdToRaiseInThisPhase = TOKENS_TO_SELL_PER_PHASE[_currentPhase] * PRICES_PER_PHASE[_currentPhase];

        usdToRaiseInNextPhase =
            (_currentPhase == NUMBER_OF_PHASES - 1)
            ?
            usdToRaiseInThisPhase
            :
            TOKENS_TO_SELL_PER_PHASE[_currentPhase + 1] * PRICES_PER_PHASE[_currentPhase + 1];

        etherPrice = getLatestEtherPriceInUsd();
        tetherPrice = getLatestTetherPriceInUsd();

        finished = isFinished();
    }

    /**
     * @dev To calculate the price in USD for given amount of tokens.
     * @param numberOfCsc No of tokens (pieces!)
     */
    function calculatePrice(uint256 numberOfCsc) public view returns (uint256, uint256) {
        uint256 USDAmount;
        uint256 amountSoldInCurrentPhase;

        uint256 total = _checkPoint == 0 ? _totalTokensSold : _checkPoint;

        require(
            _cscAmountPurchased[_msgSender()] + (numberOfCsc * CSC) <= (_maxTokensToBuy * CSC),
            "Amount exceeds max tokens to buy per wallet"
        );

        require(numberOfCsc >= _minTokensToBuy, "Amount less than min tokens to buy");

        if (numberOfCsc + total > TOTAL_TOKENS_PER_PHASE[_currentPhase] || block.timestamp >= _phaseEndTimes[_currentPhase]) {
            require(_currentPhase < (NUMBER_OF_PHASES - 1), "No more CSC can be bought");

            if (block.timestamp >= _phaseEndTimes[_currentPhase]) {
                // There must not be two phase jumps in one transaction
                require(TOTAL_TOKENS_PER_PHASE[_currentPhase] + numberOfCsc < TOTAL_TOKENS_PER_PHASE[_currentPhase + 1], "Cant purchase more in individual tx");
                USDAmount = numberOfCsc * PRICES_PER_PHASE[_currentPhase + 1];
                amountSoldInCurrentPhase = 0;
            } else {
                uint256 tokenAmountForCurrentPrice = TOTAL_TOKENS_PER_PHASE[_currentPhase] - total;

                USDAmount =
                    tokenAmountForCurrentPrice * PRICES_PER_PHASE[_currentPhase]
                    +
                    (numberOfCsc - tokenAmountForCurrentPrice) * PRICES_PER_PHASE[_currentPhase + 1];

                amountSoldInCurrentPhase = tokenAmountForCurrentPrice;
            }

        } else {
            USDAmount = numberOfCsc * PRICES_PER_PHASE[_currentPhase];
            amountSoldInCurrentPhase = numberOfCsc;
        }

        return (USDAmount, amountSoldInCurrentPhase);
    }

    function startSale() external onlyOwner {
        require(!_started, "Sale already started");

        uint256 numberOfCscNeeded = NUMBER_OF_CSC_TOKENS_FOR_EXCHANGE;
        for (uint i = 0; i < NUMBER_OF_PHASES; i++) {
            numberOfCscNeeded += TOKENS_TO_SELL_PER_PHASE[i];
        }

        require(
            _cscContract.balanceOf(address(this)) >= numberOfCscNeeded * CSC,
            "No CSC tokens available for the presale contract"
        );

        _startTime = block.timestamp;
        // Phase 0 (starting phase)
        _phaseEndTimes.push(_startTime + DEFAULT_PHASE_INTERVAL);

        _started = true;

        _vestingStartTime = getEndTime() + SAFETY_VESTING_START_TIME_OFFSET;
    }

    /**
     * @dev To buy into a presale using USDT
     * @param numberOfCsc Number of tokens to buy
     */
    function buyWithUSDT(uint256 numberOfCsc) external checkSaleState(numberOfCsc) returns (bool) {
        uint256 usdPrice;
        uint256 amountSoldInCurrentPhase;

        (usdPrice, amountSoldInCurrentPhase) = calculatePrice(numberOfCsc);

        uint256 usdtAmount = (usdPrice * USDT) / getLatestTetherPriceInUsd();

        _handleSellDynamics(numberOfCsc, amountSoldInCurrentPhase);

        _usdRaised += usdPrice;

        uint256 ourAllowance = _usdtContract.allowance(_msgSender(), address(this));
        require(usdtAmount <= ourAllowance, "Make sure to add enough USDT allowance");

        _usdtReceived += usdtAmount;

        (bool success, ) = address(_usdtContract).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _msgSender(), address(this), usdtAmount));
        require(success, "Token payment failed");

        bool cscSuccess = _cscContract.transfer(_msgSender(), numberOfCsc * CSC);
        require(cscSuccess, "Token transfer failed");

        emit TokensBought(_msgSender(), numberOfCsc, address(_usdtContract), usdtAmount, usdPrice, block.timestamp);
        return true;
    }

    /**
     * @dev To buy into a presale using ETH
     * @param numberOfCsc Number of tokens to buy
     */
    function buyWithEth(uint256 numberOfCsc) external payable checkSaleState(numberOfCsc) nonReentrant returns (bool) {
        uint256 usdPrice;
        uint256 amountSoldInCurrentPhase;

        (usdPrice, amountSoldInCurrentPhase) = calculatePrice(numberOfCsc);

        uint256 ethAmount = (usdPrice * ETH) / getLatestEtherPriceInUsd();
        require(msg.value >= ethAmount, "Less payment");
        uint256 excess = msg.value - ethAmount;

        _handleSellDynamics(numberOfCsc, amountSoldInCurrentPhase);

        _usdRaised += usdPrice;
        _ethReceived += ethAmount;

        bool success = _cscContract.transfer(_msgSender(), numberOfCsc * CSC);
        require(success, "Token transfer failed");

        if (excess > 0) _sendValue(payable(_msgSender()), excess);
        emit TokensBought(_msgSender(), numberOfCsc, address(0), ethAmount, usdPrice, block.timestamp);
        return true;
    }

    function goPublic() external {
        require(address(_lpContract) == address(0), "Liquidity pool already exists");
        require(block.timestamp > _startTime, "Presale has not started yet");
        require(_totalTokensSold > 0, "No CSC tokens sold during presale");
        require(_usdRaised > 0, "No USD raised during presale");

        require(isFinished(), "Presale is still in progress");

        uint256 cscBalance = _cscContract.balanceOf(address(this));
        require(cscBalance >= NUMBER_OF_CSC_TOKENS_FOR_EXCHANGE * CSC, "No CSC tokens available for the presale contract");

        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "No ETH tokens available for the presale contract");

        uint256 usdtToSwap = (_usdtReceived * _dexPercentage) / 100;
        _swapUsdtForEth(usdtToSwap);

        uint256 ethToPool = (_ethReceived * _dexPercentage) / 100;
        // Add ETH from USDT swap also to pool
        ethToPool += (address(this).balance - ethBalance);

        uint256 ethToPoolInUsd = (ethToPool * getLatestEtherPriceInUsd()) / ETH;
        uint256 cscToPool = (ethToPoolInUsd * CSC) / LISTING_PRICE_IN_USD;

        uint256 maxCscToPool = (cscBalance * _dexPercentage) / MAXIMUM_DEX_PERCENTAGE;
        if (cscToPool > maxCscToPool) {
            // Going higher than listing price
            cscToPool = maxCscToPool;
        }

        _createLiquidityPool(cscToPool, ethToPool);

        uint256 ethExcess = address(this).balance;
        uint256 cscExcess = _cscContract.balanceOf(address(this));
        uint256 usdtExcess = _usdtContract.balanceOf(address(this));

        if (block.timestamp < _phaseEndTimes[NUMBER_OF_PHASES - 1]) {
            _phaseEndTimes[NUMBER_OF_PHASES - 1] = block.timestamp;
        }

        _cscContract.sendOutSuccessTokens(NUMBER_OF_PHASES - 1, NUMBER_OF_PHASES, getSuccessRatePercent(NUMBER_OF_PHASES - 1));

        _vestingStartTime = block.timestamp;

        if (cscExcess > 0) {
            bool success = _cscContract.transfer(_treasuryWallet, cscExcess);
            require(success, "CSC transfer failed");
        }

        if (usdtExcess > 0) {
            (bool success, ) = address(_usdtContract).call(abi.encodeWithSignature("transfer(address,uint256)", _treasuryWallet, usdtExcess));
            require(success, "USDT transfer failed");
        }

        if (ethExcess > 0) {
            _sendValue(payable(_treasuryWallet), ethExcess);
        }
    }

    function safetyGoPublic(bool eth, bool usdt, bool csc, bool successTokens) external onlyOwner {
        // This guarantees that no one can withdraw liquidity before going public
        // Because end time CANNOT be set to the past and owner MUST wait more days to call this function
        // Until that day anyone can call goPublic() function to start the liquidity pool according to the plans
        require(block.timestamp > getEndTime() + SAFETY_GO_PUBLIC_OFFSET, "Presale and safety delay has not finished yet");

        if (successTokens) {
            _cscContract.sendOutSuccessTokens(NUMBER_OF_PHASES - 1, NUMBER_OF_PHASES, getSuccessRatePercent(NUMBER_OF_PHASES - 1));
        }

        if (usdt) {
            uint256 usdtBalance = _usdtContract.balanceOf(address(this));
            address(_usdtContract).call(abi.encodeWithSignature("transfer(address,uint256)", _treasuryWallet, usdtBalance));
        }

        if (csc) {
            uint256 cscBalance = _cscContract.balanceOf(address(this));
            _cscContract.transfer(_treasuryWallet, cscBalance);
        }

        if (eth) {
            uint256 ethBalance = address(this).balance;
            _sendValue(payable(_treasuryWallet), ethBalance);
        }
    }

    function transferFunds(uint256 ethAmount, uint256 usdtAmount) external onlyOwner {
        if (usdtAmount > 0) {
            require(
                _usdtContract.balanceOf(address(this)) >= ((_usdtReceived * _dexPercentage) / 100) + usdtAmount,
                "Not enough USDT to transfer"
            );

            address(_usdtContract).call(abi.encodeWithSignature("transfer(address,uint256)", _treasuryWallet, usdtAmount));
        }

        if (ethAmount > 0) {
            require(
                address(this).balance >= ((_ethReceived * _dexPercentage) / 100) + ethAmount,
                "Not enough ETH to transfer"
            );

            _sendValue(payable(_treasuryWallet), ethAmount);
        }
    }

    function transferLpTokens(uint256 amount) external onlyOwner {
        require(address(_lpContract) != address(0), "No LP contract set");
        require(block.timestamp >= _lpTokensUnlockDate, "LP tokens locked");
        _lpContract.transfer(owner(), amount);
    }

    function lockLpTokens(uint256 futureDate) external onlyOwner {
        require(futureDate >= block.timestamp, "Lock date must be in the future");
        require(futureDate >= _lpTokensUnlockDate, "New lock date must be later than the current one");
        _lpTokensUnlockDate = futureDate;
    }

    function setMaxTokensToBuy(uint256 maxTokensToBuy) external onlyOwner {
        require(!isFinished(), "Sale is already finished");
        require(maxTokensToBuy > 0, "Zero max tokens to buy value");
        uint256 prevValue = _maxTokensToBuy;
        _maxTokensToBuy = maxTokensToBuy;
        emit MaxTokensUpdated(prevValue, maxTokensToBuy, block.timestamp);
    }

    function setMinTokensToBuy(uint256 minTokensToBuy) external onlyOwner {
        require(!isFinished(), "Sale is already finished");
        uint256 prevValue = _minTokensToBuy;
        _minTokensToBuy = minTokensToBuy;
        emit MinTokensUpdated(prevValue, minTokensToBuy, block.timestamp);
    }

    function setCurrentPhaseEnd(uint256 newEnd) external onlyOwner {
        require(!isFinished(), "Sale is already finished");
        require(newEnd >= block.timestamp, "New phase endtime in past");
        _phaseEndTimes[_currentPhase] = newEnd;
        _vestingStartTime = getEndTime() + SAFETY_VESTING_START_TIME_OFFSET;
    }

    function setDexPercentage(uint256 dexPercentage) external onlyOwner {
        require(!isFinished(), "Sale is already finished");
        require(
            dexPercentage >= MINIMUM_DEX_PERCENTAGE && dexPercentage <= MAXIMUM_DEX_PERCENTAGE,
            "Invalid DEX percentage"
        );

        require(
            _usdtContract.balanceOf(address(this)) >= (_usdtReceived * dexPercentage) / 100,
            "Not enough USDT balance to change DEX percentage"
        );

        require(
            address(this).balance >= (_ethReceived * dexPercentage) / 100,
            "Not enough ETH balance to change DEX percentage"
        );

        _dexPercentage = dexPercentage;
    }

    function _handleSellDynamics(uint256 pcs, uint256 pcsInCurrentPhase) internal {
        _totalTokensSold += pcs;
        _soldTokensInPhase[_currentPhase] += pcsInCurrentPhase;

        if (_checkPoint != 0) _checkPoint += pcs;

        uint256 total = _totalTokensSold > _checkPoint ? _totalTokensSold : _checkPoint;

        if (total >= TOTAL_TOKENS_PER_PHASE[_currentPhase] || block.timestamp >= _phaseEndTimes[_currentPhase]) {
            if (block.timestamp >= _phaseEndTimes[_currentPhase]) {
                require(pcsInCurrentPhase == 0, "Wrong amount to be sold in next phase");
                _checkPoint = TOTAL_TOKENS_PER_PHASE[_currentPhase] + pcs;
                // Phase is already ended according the the block time
                // Do not change _phaseEndTimes[_currentPhase]
            } else {
                // Phase is incremented due to buying more tokens than available (or equal) in current phase
                // End phase now
                _phaseEndTimes[_currentPhase] = block.timestamp;
                _vestingStartTime = getEndTime() + SAFETY_VESTING_START_TIME_OFFSET;
                require(pcs >= pcsInCurrentPhase, "Wrong amount to be sold in next phase");
            }

            if (_currentPhase < NUMBER_OF_PHASES - 1) {
                uint256 prevPhaseEndTime = _phaseEndTimes[_currentPhase];
                _currentPhase += 1;
                _phaseEndTimes.push(prevPhaseEndTime + DEFAULT_PHASE_INTERVAL);

                // Next "current" phase
                _soldTokensInPhase[_currentPhase] += pcs - pcsInCurrentPhase;

                _cscContract.sendOutSuccessTokens(_currentPhase - 1, NUMBER_OF_PHASES, getSuccessRatePercent(_currentPhase - 1));
            } else {
                _cscContract.sendOutSuccessTokens(NUMBER_OF_PHASES - 1, NUMBER_OF_PHASES, getSuccessRatePercent(NUMBER_OF_PHASES - 1));
            }
        }
        _cscAmountPurchased[_msgSender()] += (pcs * CSC);
    }

    function _sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH payment failed");
    }

    function _swapUsdtForEth(uint256 usdtAmount) internal {
        if (usdtAmount > 0) {
            (bool success, ) = address(_usdtContract).call(abi.encodeWithSignature("approve(address,uint256)", address(_uniswapV2Router), usdtAmount));
            require(success, "USDT approve failed");

            address[] memory path = new address[](2);
            path[0] = address(_usdtContract);
            path[1] = _uniswapV2Router.WETH();

            _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                usdtAmount,
                0,    // slippage can happen
                path,
                address(this),
                block.timestamp + 600
            );
        }
    }

    function _createLiquidityPool(uint256 cscAmount, uint256 ethAmount) internal {
        bool success = _cscContract.approve(address(_uniswapV2Router), cscAmount);
        require(success, "CSC approve failed");

        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(_cscContract),
            cscAmount,
            0,    // slippage can happen
            0,    // slippage can happen
            address(this),
            block.timestamp + 600
        );

        _lpContract = IUniswapV2Pair(
            IUniswapV2Factory(_uniswapV2Router.factory())
                .getPair(address(_cscContract), _uniswapV2Router.WETH())
        );
    }

}
