// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./AggregatorV3Interface.sol";
import "./IUniswapOracleV3.sol";
import "./LibPriceConsumer.sol";
import "./LibPriceConsumerStorage.sol";
import "./LibClaimTokenStorage.sol";
import "./LibProtocolStorage.sol";
import "./LibAppStorage.sol";
import "./LibMeta.sol";
import "./LibDiamond.sol";
import "./IERC20Extras.sol";
import "./IUniswapV3Router.sol";
import "./IProtocolRegistry.sol";
import "./IClaimToken.sol";

/// @dev contract for getting the price of ERC20 tokens from the chainlink and AMM Dexes like uniswap etc..
contract PriceConsumerFacet is Modifiers {
    function priceConsumerFacetInit(
        address _swapRouterv3,
        address _oracle
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(msg.sender == ds.contractOwner, "Must own the contract.");

        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        require(
            !es.isInitializedPriceConsumer,
            "Already initialized Price Consumer"
        );
        es.isInitializedPriceConsumer = true;
        es.swapRouterv3 = IUniswapV3Router(_swapRouterv3);
        es.oracle = IUniswapOracleV3(_oracle);
        emit LibPriceConsumerStorage.PriceConsumerInitialized(_swapRouterv3);
    }

    /// @dev Adds a new token for which getLatestUsdPrice or getLatestUsdPrices can be called.
    /// param _tokenAddress The new token for price feed.
    /// param _chainlinkFeedAddress chainlink feed address
    /// param _enabled    if true then enabled
    /// param _decimals decimals of the chainlink price feed

    function addTokenChainlinkFeed(
        address _tokenAddress,
        address _chainlinkFeedAddress,
        bool _enabled,
        uint256 _decimals
    ) public onlyAddTokenRole(LibMeta._msgSender()) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        require(
            address(es.usdPriceAggrigators[_tokenAddress].usdPriceAggrigator) ==
                address(0),
            "GPC: already added price feed"
        );

        es.usdPriceAggrigators[_tokenAddress] = LibPriceConsumerStorage
            .ChainlinkDataFeed(
                AggregatorV3Interface(_chainlinkFeedAddress),
                _enabled,
                _decimals
            );

        emit LibPriceConsumerStorage.PriceFeedAdded(
            _tokenAddress,
            _chainlinkFeedAddress,
            _enabled,
            _decimals
        );
    }

    /// @dev Adds a new tokens in bulk for getlatestPrice or getLatestUsdPrices can be called
    /// @param _tokenAddress the new tokens for the price feed
    /// @param _chainlinkFeedAddress The contract address of the chainlink aggregator
    /// @param  _enabled price feed enabled or not
    /// @param  _decimals of the chainlink feed address

    function addBatchTokenChainlinkFeed(
        address[] memory _tokenAddress,
        address[] memory _chainlinkFeedAddress,
        bool[] memory _enabled,
        uint256[] memory _decimals
    ) external onlyAddTokenRole(LibMeta._msgSender()) {
        require(
            (_tokenAddress.length == _chainlinkFeedAddress.length) &&
                (_enabled.length == _decimals.length) &&
                (_enabled.length == _tokenAddress.length)
        );
        for (uint256 i = 0; i < _tokenAddress.length; i++) {
            addTokenChainlinkFeed(
                _tokenAddress[i],
                _chainlinkFeedAddress[i],
                _enabled[i],
                _decimals[i]
            );
        }
        emit LibPriceConsumerStorage.PriceFeedAddedBulk(
            _tokenAddress,
            _chainlinkFeedAddress,
            _enabled,
            _decimals
        );
    }

    /// @dev enable or disable a token for which getLatestUsdPrice or getLatestUsdPrices can not be called now.
    /// @param _tokenAddress The token for price feed.

    function updateAggregatorTokenStatus(
        address _tokenAddress
    ) external onlyAddTokenRole(LibMeta._msgSender()) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        es.usdPriceAggrigators[_tokenAddress].enabled = !es
            .usdPriceAggrigators[_tokenAddress]
            .enabled;
        emit LibPriceConsumerStorage.PriceFeedStatusUpdated(
            _tokenAddress,
            es.usdPriceAggrigators[_tokenAddress].enabled
        );
    }

    /// @dev update price feed address for the token incase if price feed is disabled or feed address was wrong while adding price feed address
    function updateTokenPriceFeedAddress(
        address _tokenAddress,
        address _chainlinkFeedAddress
    ) external onlyAddTokenRole(LibMeta._msgSender()) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        require(
            !es.usdPriceAggrigators[_tokenAddress].enabled,
            "GPC: price feed is enabled"
        );
        require(_tokenAddress != address(0), "GPC: token address null");
        require(_chainlinkFeedAddress != address(0), "GPC: feed address null");

        es.usdPriceAggrigators[_tokenAddress].enabled = true;
        es
            .usdPriceAggrigators[_tokenAddress]
            .usdPriceAggrigator = AggregatorV3Interface(_chainlinkFeedAddress);

        emit LibPriceConsumerStorage.PriceFeedAddressUpdated(
            _tokenAddress,
            _chainlinkFeedAddress
        );
    }

    /// @dev Use chainlink PriceAggrigator to fetch prices of the already added feeds.
    /// @param priceFeedToken address of the price feed token
    /// @return int256 price of the token in usd
    /// @return uint8 decimals of the price token

    function getTokenPriceFromChainlink(
        address priceFeedToken
    ) external view returns (int256, uint8) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        (, int256 price, , , ) = es
            .usdPriceAggrigators[priceFeedToken]
            .usdPriceAggrigator
            .latestRoundData();
        uint8 decimals = es
            .usdPriceAggrigators[priceFeedToken]
            .usdPriceAggrigator
            .decimals();

        return (price, decimals);
    }

    /// @dev multiple token prices fetch
    /// @param priceFeedToken multi token price fetch
    /// @return tokens returns the token address of the pricefeed token addresses
    /// @return prices returns the prices of each token in array
    /// @return decimals returns the token decimals in array
    function getTokensPriceFromChainlink(
        address[] memory priceFeedToken
    )
        external
        view
        returns (
            address[] memory tokens,
            int256[] memory prices,
            uint8[] memory decimals
        )
    {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        decimals = new uint8[](priceFeedToken.length);
        tokens = new address[](priceFeedToken.length);
        prices = new int256[](priceFeedToken.length);
        for (uint256 i = 0; i < priceFeedToken.length; i++) {
            (, int256 price, , , ) = es
                .usdPriceAggrigators[priceFeedToken[i]]
                .usdPriceAggrigator
                .latestRoundData();
            decimals[i] = es
                .usdPriceAggrigators[priceFeedToken[i]]
                .usdPriceAggrigator
                .decimals();
            tokens[i] = priceFeedToken[i];
            prices[i] = price;
        }
        return (tokens, prices, decimals);
    }

    /// @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
    /// @param _tokenIn address of stable coin or collateral coin
    /// @param _tokenOut address of stable coin or collateral coin
    /// @param _amount address of collateral or stable coin
    /// @return uint256 returns the tokenA price in tokenB
    function getTokenPriceFromDex(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) external view returns (uint256) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        address pairWethTokenOut = LibPriceConsumer.getPair(
            wethAddress(),
            _tokenOut
        );
        if (pairWethTokenOut == address(0)) return 0;

        // calling consult method from uniswap v3 oracle to get price of tokenIn in weth
        uint256 priceInWeth = IUniswapOracleV3(es.oracle).consult(
            _tokenIn,
            _amount,
            wethAddress()
        );

        return
            // getting weth price in tokenOut
            IUniswapOracleV3(es.oracle).consult(
                wethAddress(),
                priceInWeth,
                _tokenOut
            );
    }

    /// @dev this function will get the price of native token and will assign the price according to the derived SUN tokens
    /// @param _claimToken address of the approved claim token
    /// @param _sunToken address of the SUN token
    /// @return uint256 returns the sun token price in stable token

    function getSunTokenInStable(
        address _claimToken,
        address _stable,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256) {
        LibClaimTokenStorage.ClaimTokenData memory claimTokenData = IClaimToken(
            address(this)
        ).getClaimTokensData(_claimToken);

        uint256 pegTokensPricePercentage;
        //getting price of claim tokens in terms of stable token
        uint256 claimTokenPriceInStable = this.getTokenPriceFromDex(
            _claimToken,
            _stable,
            _amount
        );
        uint256 lengthPegTokens = claimTokenData.pegOrSunTokens.length;
        for (uint256 i = 0; i < lengthPegTokens; i++) {
            if (claimTokenData.pegOrSunTokens[i] == _sunToken) {
                pegTokensPricePercentage = claimTokenData
                    .pegOrSunTokensPricePercentage[i];
            }
        }

        return (claimTokenPriceInStable * pegTokensPricePercentage) / 10000;
    }

    function getStableInSunToken(
        address _stable,
        address _claimToken,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256) {
        LibClaimTokenStorage.ClaimTokenData memory claimTokenData = IClaimToken(
            address(this)
        ).getClaimTokensData(_claimToken);

        uint256 pegTokensPricePercentage;
        //getting price of stable tokens in terms of claim token
        uint256 stablePriceInclaimToken = this.getTokenPriceFromDex(
            _stable,
            _claimToken,
            _amount
        );

        uint256 lengthPegTokens = claimTokenData.pegOrSunTokens.length;
        for (uint256 i = 0; i < lengthPegTokens; i++) {
            if (claimTokenData.pegOrSunTokens[i] == _sunToken) {
                pegTokensPricePercentage = claimTokenData
                    .pegOrSunTokensPricePercentage[i];
            }
        }

        return (stablePriceInclaimToken * pegTokensPricePercentage) / 10000;
    }

    /// @dev get the dex router address for the approved collateral token address
    /// @param _approvedCollateralToken approved collateral token address
    /// @return address address of the dex router

    function getSwapInterface(
        address _approvedCollateralToken
    ) external view returns (address) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();

        LibProtocolStorage.Market memory marketData = IProtocolRegistry(
            address(this)
        ).getSingleApproveToken(_approvedCollateralToken);

        if (marketData.dexRouter != address(0)) {
            // swap router address uniswap or sushiswap or any uniswap like modal dex
            return marketData.dexRouter;
        } else {
            return address(es.swapRouterv3);
        }
    }

    /// @dev function checking if token price feed is enabled for chainlink or not
    /// @param _tokenAddress token address of the chainlink feed
    /// @return bool returns true or false value
    function isChainlinkFeedEnabled(
        address _tokenAddress
    ) external view returns (bool) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        return es.usdPriceAggrigators[_tokenAddress].enabled;
    }

    /// @dev get token price feed chainlink data
    function getAggregatorData(
        address _tokenAddress
    ) external view returns (LibPriceConsumerStorage.ChainlinkDataFeed memory) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        return es.usdPriceAggrigators[_tokenAddress];
    }

    /// @dev get Wrapped ETH/BNB address from the uniswap v2 router
    function wethAddress() public view returns (address) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage es = LibPriceConsumerStorage.priceConsumerStorage();
        return IUniswapV3Router(es.swapRouterv3).WETH9();
    }

    /// @dev Calculates LTV based on dex token price
    /// @param _stakedCollateralAmounts ttoken amounts
    /// @param _stakedCollateralTokens token contracts.
    /// @param _loanAmount total borrower loan amount in borrowed token.

    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts,
        address[] memory _stakedCollateralTokens,
        address _borrowedToken,
        uint256 _loanAmount
    ) external view returns (uint256) {
        uint256 totalCollateralInBorrowedToken;

        for (uint256 i = 0; i < _stakedCollateralAmounts.length; i++) {
            uint256 collatetralInBorrowed;
            address claimToken = IClaimToken(address(this))
                .getClaimTokenofSUNToken(_stakedCollateralTokens[i]);

            if (IClaimToken(address(this)).isClaimToken(claimToken)) {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        this.getSunTokenInStable(
                            claimToken,
                            _borrowedToken,
                            _stakedCollateralTokens[i],
                            _stakedCollateralAmounts[i]
                        )
                    );
            } else {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        this.getCollateralPriceinStable(
                            _stakedCollateralTokens[i],
                            _borrowedToken,
                            _stakedCollateralAmounts[i]
                        )
                    );
            }

            totalCollateralInBorrowedToken =
                totalCollateralInBorrowedToken +
                collatetralInBorrowed;
        }
        return (totalCollateralInBorrowedToken * 100) / _loanAmount;
    }

    /// @dev function to get altcoin amount in stable coin.
    /// @param _stableCoin of the altcoin
    /// @param _altCoin address of the stable
    /// @param _collateralAmount amount of altcoin

    function getCollateralPriceinStable(
        address _altCoin,
        address _stableCoin,
        uint256 _collateralAmount
    ) external view returns (uint256) {
        if (
            this.isChainlinkFeedEnabled(_altCoin) &&
            this.isChainlinkFeedEnabled(_stableCoin)
        ) {
            (int256 collateralInUsd, ) = this.getTokenPriceFromChainlink(
                _altCoin
            );
            (int256 stableInUsd, ) = this.getTokenPriceFromChainlink(
                _stableCoin
            );
            uint256 collateralDecimals = IERC20Extras(_altCoin).decimals();
            uint256 stableDecimals = IERC20Extras(_stableCoin).decimals();
            uint256 altRateInStable = (uint256(collateralInUsd) *
                10 ** stableDecimals) / uint256(stableInUsd);
            return
                (_collateralAmount * altRateInStable) /
                10 ** collateralDecimals;
        } else {
            return (
                this.getTokenPriceFromDex(
                    _altCoin,
                    _stableCoin,
                    _collateralAmount
                )
            );
        }
    }

    /// @dev function to get stablecoin price in altcoin
    /// using this function is the liqudation autosell off
    function getStablePriceInCollateral(
        address _stableCoin,
        address _altCoin,
        uint256 _stableCoinAmount
    ) external view returns (uint256) {
        if (
            this.isChainlinkFeedEnabled(_altCoin) &&
            this.isChainlinkFeedEnabled(_stableCoin)
        ) {
            (int256 collateralInUsd, ) = this.getTokenPriceFromChainlink(
                _altCoin
            );
            (int256 stableInUsd, ) = this.getTokenPriceFromChainlink(
                _stableCoin
            );
            uint256 stableDecimals = IERC20Extras(_stableCoin).decimals();
            uint256 collateralDecimals = IERC20Extras(_altCoin).decimals();
            uint256 stableRateInAltcoin = (uint256(stableInUsd) *
                10 ** collateralDecimals) / uint256(collateralInUsd);
            return
                (_stableCoinAmount * stableRateInAltcoin) /
                10 ** stableDecimals;
        } else {
            return (
                this.getTokenPriceFromDex(
                    _stableCoin,
                    _altCoin,
                    _stableCoinAmount
                )
            );
        }
    }
}
