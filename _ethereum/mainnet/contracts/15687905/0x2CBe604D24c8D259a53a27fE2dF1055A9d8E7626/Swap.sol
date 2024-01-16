// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "./ChainlinkClient.sol";
import "./BaseSwap.sol";
import "./ISwapExtras.sol";
import "./Lib.sol";

contract Swap is ChainlinkClient, BaseSwap, ISwapExtras {
    using ChainlinkLib for *;
    using SwapLib for *;
    using PriceLib for *;
   //chainlink appi request
    using Chainlink for Chainlink.Request;
  
    //check for price redirection
    bool public chainlinkFeedEnabled;
    //contrains API call info
    ChainlinkLib.ApiInfo private apiInfo;
    //Current Price and timeout info
    PriceLib.PriceInfo private priceInfo;
   //fee in terms on LINK tokenns
    uint256 private chainlinkTokenFee;
    //Chainlink Job Id
    bytes32 private jobId;

    /// @param _commodityToken the commodity token
    /// @param _stableToken the stable token
    /// @param _dexSettings comm-dex name, tradefee, dex-admin, rateTimeout for DEX
    /// @param _apiData API from where to fetch the price, buyPath and sellPath for BUY/SELL price in API response

    constructor(
        //dex tokens
        address _commodityToken,
        address _stableToken,
        //dex params
        SwapLib.DexSetting memory _dexSettings,
        //endpoint params
        ChainlinkLib.ApiInfo memory _apiData
    ) {
        require(
            _dexSettings.dexAdmin != address(0),
            "Invalid address"
        );
        require(_dexSettings.unitMultiplier > 0, "Invalid  _unitMultiplier");

        dexData.commodityToken = _commodityToken;
        dexData.stableToken = _stableToken;
        dexSettings.comdexName = _dexSettings.comdexName;
        dexSettings.tradeFee = _dexSettings.tradeFee;
        dexSettings.rateTimeOut = _dexSettings.rateTimeOut;
        dexSettings.dexAdmin = _dexSettings.dexAdmin;
        dexSettings.unitMultiplier= _dexSettings.unitMultiplier ;
        dexSettings.stableToUSDPriceFeed = _dexSettings.stableToUSDPriceFeed;
        dexSettings.buySpotDifference = _dexSettings.buySpotDifference;
        dexSettings.sellSpotDifference = _dexSettings.sellSpotDifference;
        apiInfo = _apiData;

        stableTokenPriceFeed = AggregatorV3Interface(_dexSettings.stableToUSDPriceFeed);
    }

    /// @dev initializes the Swap with details
    /// @param _chainlinkInfo Chainlink token, oracle, pricefeed address and flag to use price source

    function initChainlinkAndPriceInfo(
        ChainlinkLib.ChainlinkInfo calldata _chainlinkInfo
    ) external onlyOwner {
        if (_chainlinkInfo.chainlinkFeedEnabled) {
            chainlinkFeedEnabled = true;
            priceFeed = AggregatorV3Interface(
                _chainlinkInfo.chianlinkPriceFeed
            );
            stableTokenPriceFeed = AggregatorV3Interface(dexSettings.stableToUSDPriceFeed);
        }
        setChainlinkToken(_chainlinkInfo.chainlinkToken);
        setChainlinkOracle(_chainlinkInfo.chainlinkOracle);

        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        chainlinkTokenFee = (1 * LINK_DIVISIBILITY) / 10; // 0.1 LINK Token as fee for each request

        priceInfo.rates = new uint256[](2);
        priceInfo.chainlinkRequestId = new bytes32[](2);
        priceInfo.lastTimeStamp = new uint256[](2);
        priceInfo.lastPriceFeed = new uint256[](2);

        //Load both buy and sell rate
        setPriceFeed(SwapLib.BUY_INDEX);
        setPriceFeed(SwapLib.SELL_INDEX);
    }

    /// @notice Swaps from commodity token to another token and vice versa
    /// @param _amountIn Amount of tokens user want to give for swap (in decimals of _from token)
    /// @param _from token that user want to give
    /// @param _to token that user wants in result of swap
    function swap(
        uint256 _amountIn,
        address _from,
        address _to
    ) external virtual whenNotPaused{
        require(_amountIn > 0, "wrong amount");
        require(
            (_from == dexData.commodityToken && _to == dexData.stableToken) ||
                (_to == dexData.commodityToken && _from == dexData.stableToken),
            "wrong pair"
        );

        uint256 amountFee = (_amountIn * dexSettings.tradeFee) / (10**10);

        if (_from == dexData.commodityToken) {
            if (!chainlinkFeedEnabled) {
                //reqiest a fresh price from API
                setPriceFeed(SwapLib.SELL_INDEX);
                //revert for outdated price
                require(!isRateTimeout(SwapLib.SELL_INDEX), "rate timeout");
            }

            uint256 commodityAmount = _amountIn - amountFee;
            uint256 stableAmount = getAmountOut(commodityAmount, false);
            if (dexData.reserveStable < stableAmount)
                emit LowstableTokenalance(dexData.stableToken, dexData.reserveStable);
            require(dexData.reserveStable >= stableAmount, "not enough liquidity");

            TransferHelper.safeTransferFrom(
                dexData.commodityToken,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.stableToken, msg.sender, stableAmount);

            dexData.reserveCommodity = dexData.reserveCommodity + commodityAmount;
            dexData.reserveStable = dexData.reserveStable - stableAmount;
            dexData.totalFeeCommodity = dexData.totalFeeCommodity + amountFee;
            emit Swapped(msg.sender, _amountIn, stableAmount, SwapLib.SELL_INDEX);
        } else {
            if (!chainlinkFeedEnabled) {
                //reqiest a fresh price from API
                setPriceFeed(SwapLib.BUY_INDEX);
                //revert for outdated price
                require(!isRateTimeout(SwapLib.BUY_INDEX), "rate timeout");
            }
            uint256 stableAmount = _amountIn - amountFee;
            uint256 commodityAmount = getAmountOut(stableAmount, true);
            if (dexData.reserveCommodity < commodityAmount)
                emit LowstableTokenalance(dexData.commodityToken, dexData.reserveCommodity);
            require(dexData.reserveCommodity >= commodityAmount, "not enough liquidity");

            TransferHelper.safeTransferFrom(
                dexData.stableToken,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.commodityToken, msg.sender, commodityAmount);

            dexData.reserveCommodity = dexData.reserveCommodity - commodityAmount;
            dexData.reserveStable = dexData.reserveStable + stableAmount;
            dexData.totalFeeStable = dexData.totalFeeStable + amountFee;
            emit Swapped(msg.sender, _amountIn, commodityAmount, SwapLib.BUY_INDEX);
        }
    }



    /// @notice adds liquidity for both assets
    /// @dev stableAmount should be = commodityAmount * price
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function addLiquidity(uint256 commodityAmount, uint256 stableAmount)
        external
        virtual
        onlyOwner
    {
        uint amount = getAmountOut(commodityAmount, false);
        require(
            amount == stableAmount,
            "amounts should be equal"
        );
        super._addLiquidity(commodityAmount, stableAmount);
    }

    /// @notice removes liquidity for both assets
    /// @dev stableAmount should be = commodityAmount * price
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function removeLiquidity(uint256 commodityAmount, uint256 stableAmount)
        external
        virtual
        onlyOwner
    {
        uint amount = getAmountOut(commodityAmount, false);//false flag to get sell price
        require(
            amount == stableAmount,
            "commodityAmount should be equal"
        );
        super._removeLiquidity(commodityAmount, stableAmount);
    }

    // rate between token A and token B * (10**8)

    /// @dev not for user call, only chainlink oracle will call it
    /// @notice sets the current rate in smart contract fetched from API
    /// @param _requestId requestId for chainlink oracle
    /// @param _rate new price to be stored in smart contract

    function fulfill(bytes32 _requestId, uint256 _rate)
        external
        recordChainlinkFulfillment(_requestId)
    {
        uint256 index = (_requestId ==
            priceInfo.chainlinkRequestId[SwapLib.BUY_INDEX])
            ? SwapLib.BUY_INDEX
            : SwapLib.SELL_INDEX;
        priceInfo.rates[index] = _rate;
        if (priceInfo.lastPriceFeed[index] == 0)
            // first time priceInfo.lastPriceFeed will be same
            priceInfo.lastPriceFeed[index] = _rate;
        emit RequestRateFulfilled(_requestId, _rate);
    }

    /// @notice sets the flag that where to fetch price from
    /// @param _flag true => fetch from chainlink priceFeed, false => fetch from API
    function setChainlinkFeedEnable(bool _flag) external onlyOwner {
        require(_flag != chainlinkFeedEnabled, "Already Enabled or Disabled");
        chainlinkFeedEnabled = _flag;

        emit ChainlinkFeedEnabled(_flag);
    }

    /// @notice sets url from where the price will be fetched
    /// @param _newUrl the url for endpoint

    function setApiUrl(string calldata _newUrl) external onlyOwner {
        apiInfo._apiUrl = _newUrl;
        emit ApiUrlChanged(_newUrl);
    }

    /// @notice sets Buypath
    /// @param _newBuyPath the BuyPath from API url

    function setBuyPath(string calldata _newBuyPath) external onlyOwner {
        apiInfo._chainlinkRequestPath[SwapLib.BUY_INDEX] = _newBuyPath;
        emit ApiBuyPathChanged(_newBuyPath);
    }

    /// @notice sets SellPath
    /// @param _newSellPath the SellPath from API url

    function setSellPath(string calldata _newSellPath) external onlyOwner {
        apiInfo._chainlinkRequestPath[SwapLib.SELL_INDEX] = _newSellPath;
        emit ApiSellPathChanged(_newSellPath);
    }

    // CommDEX admin functions

    /// @notice sets chainlinkcommodityTokenddress
    /// @param _newChainlinkAddr the updated chainlink token address
    function setChainlinkcommodityTokenddress(address _newChainlinkAddr)
        external
        onlyComdexAdmin
    {
        setChainlinkToken(_newChainlinkAddr);
        emit ChainlinkcommodityTokenddressChanged(_newChainlinkAddr);
    }
    /// @notice sets chainlink oralce address
    /// @param _newChainlinkOracleAddr the updated chainlink oracle address
    function setChainlinkOracleAddress(address _newChainlinkOracleAddr)
        external
        onlyComdexAdmin
    {
        setChainlinkOracle(_newChainlinkOracleAddr);

        emit ChainlinkOracleAddressChanged(_newChainlinkOracleAddr);
    }

    /// @notice sets the rate timeout
    /// @param _newDuration updated timeout 

    function setRateTimeOut(uint256 _newDuration) external onlyComdexAdmin {
        require(_newDuration >= 120 && _newDuration <= 300, "Wrong Duration!");
        dexSettings.rateTimeOut = _newDuration;
        emit RateTimeoutChanged(_newDuration);
    }

    /// @dev Get buy or sell rate
    /// @param _rateIndex 0 for buy 1 for sell
    /// @return Either buy rate or sell rate depending on index
    function getRate(uint256 _rateIndex) external view returns (uint256) {
        return priceInfo.rates[_rateIndex];
    }

    /// @dev Get buy or sell priceInfo.lastPriceFeed
    /// @param _flag 0 for buy 1 for sell
    /// @return Either buy  or sell priceInfo.lastPriceFeed
    function getlastPriceFeed(uint256 _flag) external view returns (uint256) {
        return priceInfo.lastPriceFeed[_flag];
    }

    /// @dev Allow withdraw of Link tokens from the contract
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    // // internal functions

    // function convertPrice( // removing the 8 decimals of price from API/chainlink 
    //     uint256 _index,
    //     uint256 _amount,
    //     uint256 price
    // ) internal pure returns (uint256) {
    //     // price = (price * dexSettings.unitMultiplier) / (10**18);
    //     if (_index == SwapLib.SELL_INDEX) return (_amount * price) / (10**8);
    //     else return (_amount * (10**8)) / price;
    // }

    /// @dev fetch price based on chainlinkFeedEnabled flag
    /// @return returns amount of tokens user will get 

    function fetchPrice(uint256 _index)
        internal view
        returns (uint256)
    {
        // fetch from chainLink when feed enabled
        if (chainlinkFeedEnabled)
            return  getChainLinkFeedPrice();
        // when chainLinkPriceFeed is disabled
        else{ 
            
            return (priceInfo.lastPriceFeed[_index] * dexSettings.unitMultiplier)/(10**18);
        }

    }

    function setPriceFeed(uint256 _isSale) internal {
        if (priceInfo.rates[_isSale] != 0) {
            priceInfo.lastTimeStamp[_isSale] = block.timestamp;
            priceInfo.lastPriceFeed[_isSale] = priceInfo.rates[_isSale];
        }
        priceInfo.chainlinkRequestId[_isSale] = requestVolumeData(_isSale);
    }

    function isRateTimeout(uint256 _isSale) internal view returns (bool) {
        if (priceInfo.lastTimeStamp[_isSale] == 0) return true;
        return (
            block.timestamp - priceInfo.lastTimeStamp[_isSale] >
            dexSettings.rateTimeOut
        );
        // true: the price feed is expired
        // false: the price feed is not expired
    }

    function requestVolumeData(uint256 flag)
        internal
        returns (bytes32 requestRate)
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        req.add("get", apiInfo._apiUrl);
        req.add("path", apiInfo._chainlinkRequestPath[flag]); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10**8;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, chainlinkTokenFee);
    }

    function getAmountOut(uint256 _amountIn, bool flag) public view returns(uint256){
        if(flag){//buy price for 1 unit of commdotiy token
            uint commodityUnitPrice = convertUSDToStable(fetchPrice(SwapLib.BUY_INDEX));
            commodityUnitPrice = commodityUnitPrice + ((commodityUnitPrice * dexSettings.buySpotDifference) / 10000) ; // adding 1.12% from spot price
            uint256 commodityAmount = (_amountIn * (10**8)) / commodityUnitPrice;
            commodityAmount = SwapLib.normalizeAmount(commodityAmount, dexData.stableToken, dexData.commodityToken);
            return commodityAmount;
        }
        else{//sell price for 1 unit of commodity token
            uint256 stableAmount = (_amountIn * fetchPrice(SwapLib.SELL_INDEX)) / (10**8);
            stableAmount = convertUSDToStable(stableAmount);
            stableAmount = stableAmount - ((stableAmount * dexSettings.sellSpotDifference)/(10000)); // deducting 1.04% out of spot price
            stableAmount = SwapLib.normalizeAmount(stableAmount, dexData.commodityToken, dexData.stableToken);
            return stableAmount;
        }
    }

}
