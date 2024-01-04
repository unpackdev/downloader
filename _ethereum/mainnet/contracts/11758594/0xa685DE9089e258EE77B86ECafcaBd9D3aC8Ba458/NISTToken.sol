// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;
import "./Ownable.sol";
import "./NitroStaking.sol";
import "./ERC20.sol";
import "./Pausable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./UniswapV2OracleLibrary.sol";

// @dev DegenerateGameTheorist
contract NitroStakingToken is ERC20, NitroStaking, Ownable, Pausable {
    using SafeMath for uint256;

    /// @notice Scale factor for NITRO calculations
    uint256 public constant scaleFactor = 1e18;

    /// @notice Total supply
    uint256 public constant total_supply = 2049 ether;

    /// @notice uniswap listing rate
    uint256 public constant INITIAL_TOKENS_PER_ETH = 2 * 1 ether;

    /// @dev The minimum amount of time an address must be above minimumRewardBalance to receive rewards (1 hour in seconds)
    uint256 minimumBalanceHoldingTime = 1 hours;

    /// @notice self-explanatory
    address public constant uniswapV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    address public initialDistributionAddress;

    address public presaleContractAddress;

    uint256 public presaleInitFunds;

    /// @notice liquidity sources (e.g. UniswapV2Router)
    mapping(address => bool) public whitelistedSenders;

    /// @notice exchange addresses (tokens sent here will count as sell orders in NITRO Protocol)
    mapping(address => bool) public exchangeAddresses;

    /// @notice uniswap pair for LAMBO/ETH
    address public uniswapPair;

    /// @notice Whether or not this token is first in uniswap LAMBO<>ETH pair
    bool public isThisToken0;

    /// @notice last TWAP update time (Short calculation)
    uint32 public blockTimestampLast;

    /// @notice last TWAP cumulative price (Short calculation)
    uint256 public priceCumulativeLast;

    /// @notice last TWAP average price (Short calculation)
    uint256 public priceAverageLast;

    /// @notice last TWAP update time
    uint32 public blockTimestampLastLong;

    /// @notice last TWAP cumulative price
    uint256 public priceCumulativeLastLong;

    /// @notice last TWAP average price
    uint256 public priceAverageLastLong;

    /// @notice TWAP min delta (48-hour)
    uint256 public minDeltaTwapLong;

    /// @notice TWAP min delta (Short)
    uint256 public minDeltaTwapShort;

    /// @notice The previous calculated Nitro value for buyers
    uint256 public lastBuyNitroPercent;

    /// @notice The previous calculated Nitro value for sellers
    uint256 public lastSellNitroPercent;

    //Lets us check to see if the user account is moving lambo at this address' request
    address public uniswapv2RouterAddress;

    //The contract describing the LP tokens users can stake
    IERC20 public LPTokenContract;

    //Emittable Events

    event TwapUpdated(uint256 priceCumulativeLast, uint256 blockTimestampLast, uint256 priceAverageLast);

    event LongTwapUpdated(uint256 priceCumulativeLastLong, uint256 blockTimestampLastLong, uint256 priceAverageLastLong);

    event MaxSellRemovalUpdated(uint256 new_MSR);

    event MaxBuyBonusUpdated(uint256 new_MBB);

    event ExchangeListUpdated(address exchangeAddress, bool isExchange);

//                  ------------------ Contract Start Functions ---------------------                //
    constructor(
        uint256 _minDeltaTwapLong,
        uint256 _minDeltaTwapShort,
        address rlrToken
    )
    public
    Ownable()
    ERC20("Nitro Staking Token", "NIST")
    {
        previousRewardDistributionTimestamp = block.timestamp;
        setMinDeltaTwap(_minDeltaTwapLong, _minDeltaTwapShort);
        _setMaxBuyBonusPercentage(5*scaleFactor.div(100));
        _changeMaxSellRemoval(10*scaleFactor.div(100));
        initialDistributionAddress = owner(); //The contract owner handles all initial distribution, except for presale
        _distributeTokens();
        initPair();
        _pause();
        setUniswapRouterAddress(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        //Approve uniswap router to spend nist
        _approve(address(this), uniswapv2RouterAddress, uint256(-1));
        whitelistedSenders[address(this)] = true;//Whitelist the contract itself to swap to eth without burn
        RLR = IKeep3rV1Mini(rlrToken);
    }

    modifier whenNotPausedOrInitialDistribution(address tokensender) { //Only used on transfer function
        require(!paused() || msg.sender == initialDistributionAddress || _isWhitelistedSender(msg.sender) || (msg.sender == uniswapv2RouterAddress && tokensender == owner()), "!paused && !initialDistributionAddress !InitialLiquidityProvider");
        _;
    }

    modifier onlyInitialDistributionAddress() { //Only used to initialize twap
        require(msg.sender == initialDistributionAddress, "!initialDistributionAddress");
        _;
    }

    function _distributeTokens()
    internal
    {
        _mint(address(this), total_supply);
        setWhitelistedSender(address(this), true);
    }

    /*
     * Initialize the uniswap pair address to predict it and define it as an exchange address.
     */
    function initPair() internal {
        // Create a uniswap pair for this new token
        uniswapPair = IUniswapV2Factory(uniswapV2Factory).createPair(address(this), router.WETH());
        setExchangeAddress(uniswapPair, true);
        (address token0,) = UniswapV2Library.sortTokens(address(this), router.WETH());
        isThisToken0 = (token0 == address(this));
    }
/*
    function _initializePair() internal {
        (address token0, address token1) = UniswapV2Library.sortTokens(address(this), address(WETH));
        isThisToken0 = (token0 == address(this));
        uniswapPair = UniswapV2Library.pairFor(uniswapV2Factory, token0, token1);
        setExchangeAddress(uniswapPair, true);
    }
*/
    function setUniswapRouterAddress(address newUniRouterAddy) public onlyOwner {
        uniswapv2RouterAddress = newUniRouterAddy;
    }

    function setLiquidityTokenContract(address LPTokenAddy) public onlyOwner {
        LPTokenContract = IERC20(LPTokenAddy);
    }

//////////////////---------------- Administrative Functions ----------------///////////////
    /**
     * @dev Unpauses all transfers from the distribution address (initial liquidity pool).
     */
    function unpause() external virtual onlyOwner {
        super._unpause();
    }

//////////////////----------------Modify Nitro Protocol Variables----------------///////////////

    //Modify the maxSellRemoval
    function changeMaxSellRemoval(uint256 maxSellRemoval) public onlyOwner {
        require(maxSellRemoval < 100, "Max Sell Removal is too high!");
        require(maxSellRemoval > 0, "Max Sell Removal is too small!");
        //Send it to the NitroProtocol
        _changeMaxSellRemoval(maxSellRemoval);

        //Emit this transaction
        emit MaxSellRemovalUpdated(maxSellRemoval);
    }

    /*
     * Sets the address of the presale contract ; required for project to work properly.
     * The presale contract address can only be set one time, to prevent re-sending of the 508 lambo.
     */
    function setPresaleContractAddress(address presaleContract) public onlyOwner {
        //We only want this to fire off once so the dev can't do any shady shit
        if(presaleContractAddress==address(0)){
            //Store address for posterity
            presaleContractAddress = presaleContract;

            //Whitelist the presale contract so that it can transfer tokens while contract is paused
            setWhitelistedSender(presaleContractAddress, true);

            //Send the tokens to the presale contract.
            super._transfer(address(this), presaleContractAddress, balanceOf(address(this)));
            initialDistributionAddress = presaleContract;
            //Transfer ownership to presale contract
            transferOwnership(presaleContract);
        }
    }

    /**
     * @dev Set the maximum percent order volume of bonus tokens for buyers
     */
    function setMaxBuyBonusPercentage(uint256 _maxBuyBonus) public onlyOwner {
        require(_maxBuyBonus < 100*scaleFactor.div(100), "Max Buy Bonus is too high!");
        require(_maxBuyBonus > 0, "Max Buy Bonus is too small!");
        _setMaxBuyBonusPercentage(_maxBuyBonus);

        //Emit Buy Bonus was updated
        emit MaxBuyBonusUpdated(_maxBuyBonus);
    }

//////////////////----------------Modify Contract Variables----------------///////////////

    /**
     * @dev Min time elapsed before twap is updated.
     */
    function setMinDeltaTwap(uint256 _minDeltaTwapLong, uint256 _minDeltaTwapShort) internal {
        require(_minDeltaTwapLong > 1 seconds, "Minimum delTWAP (Long) is too small!");
        require(_minDeltaTwapShort > 1 seconds, "Minimum delTWAP (Short) is too small!");
        require(_minDeltaTwapLong > _minDeltaTwapShort, "Long delta is smaller than short delta!");
        minDeltaTwapLong = _minDeltaTwapLong;
        minDeltaTwapShort = _minDeltaTwapShort;
    }

    /**
     * @dev Sets a whitelisted sender/receiver (nitro protocol does not apply).
     */
    function setWhitelistedSender(address _address, bool _whitelisted) public onlyOwner {
        whitelistedSenders[_address] = _whitelisted;
    }

    /**
     * @dev Sets a known exchange address (tokens sent from these addresses will count as buy orders, tokens sent to these addresses count as sell orders)
     */
    function setExchangeAddress(address _address, bool _isexchange) public onlyOwner {
        exchangeAddresses[_address] = _isexchange;

        emit ExchangeListUpdated(_address, _isexchange);
    }


    function _isWhitelistedSender(address _sender) internal view returns (bool) {
        return whitelistedSenders[_sender];
    }

    //Public to allow us to easily update exchange addresses in the future
    function isExchangeAddress(address _sender) public view returns (bool) {
        return exchangeAddresses[_sender];
    }

    function setRelayerJobAddress(address job) public onlyOwner {
        RelayerJob = payable(job);
    }

//                  ------------------ Nitro Implementation ---------------------                //

    function _transfer(address sender, address recipient, uint256 amount)
        internal
        virtual
        override
        whenNotPausedOrInitialDistribution(sender)
    {
        //If this isn't a whitelisted sender(such as, this contract itself, the distribution address, or the router)
        if(!_isWhitelistedSender(sender)){
            //if msg sender is an exchange, then this was a buy
            if(isExchangeAddress(sender)){
                _updateTwapsAndNitro();
                //Perform the core transaction (exchange address to user)
                super._transfer(sender, recipient, amount);
                //Calculate how many bonus tokens they've earned
                uint256 bonus_tokens_amount = lastBuyNitroPercent.mul(amount).div(scaleFactor);

                //Check we can afford it from the Nitro Protocol balance
                if(balanceOf(address(this)) > bonus_tokens_amount.add(_totalNistToDist)){
                    super._transfer(address(this), recipient, bonus_tokens_amount);
                }

            //if recipient is an exchange, then this was a sell
            }else if(isExchangeAddress(recipient)) {
                _updateTwapsAndNitro();
                //Calculate how many tokens need to be removed from the order
                uint256 removed_tokens_amount = lastSellNitroPercent.mul(amount).div(scaleFactor);
                //Remove the tokens from the amount to be sent
                amount = amount.sub(removed_tokens_amount,"sellUnderflow");
                updateStakingOutputPerSecond(_totalNistToDist.add(removed_tokens_amount.div(2)), remainingNISTToAllocate.add(removed_tokens_amount.div(2)));
                //Perform the core transaction (user to exchange address)
                super._transfer(sender, recipient, amount);

                //Send the nitro tokens to this contract so we can swap them for eth
                super._transfer(sender, address(this), removed_tokens_amount);

                //Take this opportunity to update staking data for this nonwhitelisted,nonexchange sender
                updateStake(sender, balanceOf(sender));
            }else {
                //Take this opportunity to update staking data for this nonwhitelisted, nonexchange sender
                updateStake(sender, balanceOf(sender).sub(amount));
                //Perform the core transaction (user to user)
                super._transfer(sender, recipient, amount);
            }
        }else {
            //Perform the core transaction (whitelisted to anything)
            super._transfer(sender, recipient, amount);
        }
        //Tell the NitroStaker to update the recipients possible staking balance
        if(!_isWhitelistedSender(recipient) && !isExchangeAddress(recipient)) updateStake(recipient, balanceOf(recipient));

    }


//                  ------------------ TWAP Functions ---------------------                //

    /*
     * This function updates the most realtime price you can possibly get, given a short mindeltatwapshort (5-10 minutes)
     */
    function getCurrentShortTwap() public view returns (uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
        );

        return FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));
    }

    /*
     * Use this function to get the current short TWAP
     */
    function getLastShortTwap() public view returns (uint256) {
        return priceAverageLast;
    }

    /*
     * Use this function to get the current 48-hour TWAP
     */
    function getLastLongTwap() public view returns (uint256) {
        return priceAverageLastLong;
    }

    /**
     * @notice This function updates the short TWAP Given the short TWAP period has passed.
     * @dev The Nitro % is also updated given that either TWAP was changed - reducing # of calcs on user transfer
     */
    function _updateTwapsAndNitro() internal virtual {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

        uint32 timeElapsedShort = blockTimestamp - blockTimestampLast; // overflow is desired
        uint32 timeElapsedLong = blockTimestamp - blockTimestampLastLong;

        bool recalculateNitro = false;

        if (timeElapsedShort > minDeltaTwapShort) {

            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224((priceCumulative - priceCumulativeLast) / timeElapsedShort)
            );

            priceCumulativeLast = priceCumulative;
            blockTimestampLast = blockTimestamp;

            priceAverageLast = FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));

            recalculateNitro = true;
        }

        if (timeElapsedLong > minDeltaTwapLong) {

            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224((priceCumulative - priceCumulativeLastLong) / timeElapsedLong)
            );

            priceCumulativeLastLong = priceCumulative;
            blockTimestampLastLong = blockTimestamp;

            priceAverageLastLong = FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));

            recalculateNitro = true;
        }
        if(recalculateNitro){
            (lastBuyNitroPercent, lastSellNitroPercent) = calculateCurrentNitroRate();
        }
    }

    /**
     * @dev Initializes the TWAP cumulative values for the burn curve.
     */
    function initializeTwap() external onlyInitialDistributionAddress {
        require(blockTimestampLast == 0, "Both TWAPS already initialized");
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);

        uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

        //Initialize the short TWAP values
        blockTimestampLast = blockTimestamp;
        priceCumulativeLast = priceCumulative;
        priceAverageLast = INITIAL_TOKENS_PER_ETH;

        //Initialize the long TWAP values
        blockTimestampLastLong = blockTimestamp;
        priceCumulativeLastLong = priceCumulative;
        priceAverageLastLong = INITIAL_TOKENS_PER_ETH;
    }
//                  ------------------ User Functions ---------------------                //

    /*
     * Function if for some reason the predicted trading pair address doesn't match real life trading pair address.
     */
    function setUniswapPair(address newUniswapPair) public onlyOwner {
        setExchangeAddress(uniswapPair, false);

        uniswapPair = newUniswapPair;
        updateStake(uniswapPair, 0);

        setExchangeAddress(uniswapPair, true);
    }

    /**
     * @notice Changes the minimum auto-payout balance
     */
    function updateMinimumAutoPayout(uint256 new_min) public onlyOwner {
        updateMinimumAutoPayoutBalance(new_min);
    }

    /**
     * @notice Calculates the current running % for the Nitro protocol. That is,
     *  The percent bonus tokens for any buyers at the current moment
     *  The percent tokens removed for any sellers at the current moment
     *  This is calculated using the TWAP and the realtimeprice. Calling this DOESN'T Update the TWAP.
     *
     * @return buyNitro A uint256 of 0.XX * 1 eth units, where XX is the current % for buyers (6% will return 0.06*1ether)
     * @return sellNitro A uint256 of 0.XX * 1 eth units, where XX is the current % for sellers (6% will return 0.06*1ether)
     */
    function calculateCurrentNitroRate() public view returns (uint256 buyNitro, uint256 sellNitro) {
        //The units on both of these is tokens per eth
        uint256 currentRealTimePrice = getLastShortTwap();
        uint256 currentTwap = getLastLongTwap();
        uint256 nitro;

        //Calculate the Nitro rate based on which is larger to keep it positive
        if(currentRealTimePrice > currentTwap){
            //Calculation explanation:
            //(RTP-TWAP)*scaleFactor/TWAP is typical percent calc but with the scaleFactor moved up b/c uint256
            // The *scaleFactor.dv has to cancel out the scaleFactor to get back to fractions of 100, but in units of ether
            // nitro = (currentRealTimePrice.sub(currentTwap).mul(scaleFactor).div(currentTwap))*scaleFactor.div(scaleFactor);
            nitro = (currentRealTimePrice.sub(currentTwap).mul(scaleFactor).div(currentTwap)); 
        }
        else{
            //Simply the above calculation * -1 to offset the negative
            nitro = (currentTwap.sub(currentRealTimePrice).mul(scaleFactor).div(currentTwap));
        }

        //Validate that the nitro value is within the defined bounds and return
        buyNitro = (nitro > maxBuyBonus()) ? maxBuyBonus() : nitro;
        sellNitro = (nitro.mul(2) > maxSellRemoval()) ? maxSellRemoval() : nitro.mul(2);
    }
}