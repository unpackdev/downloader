// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

import "./Declarations.sol";

abstract contract OracleHelper is Declarations {

    /**
     * @dev Adds priceFeed for a given token.
     */
    function _addOracle(
        address _tokenAddress,
        IPriceFeed _priceFeedAddress,
        address[] calldata _underlyingFeedTokens
    )
        internal
    {
        if (priceFeed[_tokenAddress] > ZERO_FEED) {
            revert OracleAlreadySet();
        }

        priceFeed[_tokenAddress] = _priceFeedAddress;

        _tokenDecimals[_tokenAddress] = IERC20(
            _tokenAddress
        ).decimals();

        underlyingFeedTokens[_tokenAddress] = _underlyingFeedTokens;
    }

    /**
     * @dev Adds uniTwapPoolInfo for a given token.
     */
    function _writeUniTwapPoolInfoStruct(
        address _tokenAddress,
        address _oracle,
        bool _isUniPool
    )
        internal
    {
        uniTwapPoolInfo[_tokenAddress] = UniTwapPoolInfo({
            oracle: _oracle,
            isUniPool: _isUniPool
        });
    }

    /**
     * @dev Adds uniTwapPoolInfo for a given token and its derivative.
     */
    function _writeUniTwapPoolInfoStructDerivative(
        address _tokenAddress,
        address _partnerTokenAddress,
        address _oracleAddress,
        address _partnerOracleAddress,
        bool _isUniPool
    )
        internal
    {
        _writeUniTwapPoolInfoStruct(
            _tokenAddress,
            _oracleAddress,
            _isUniPool
        );

        derivativePartnerTwap[_tokenAddress] = DerivativePartnerInfo(
            _partnerTokenAddress,
            _partnerOracleAddress
        );
    }

    function _getRelativeDifference(
        uint256 _answerUint256,
        uint256 _fetchTwapValue
    )
        internal
        pure
        returns (uint256)
    {
        if (_answerUint256 > _fetchTwapValue) {
            return _answerUint256
                * PRECISION_FACTOR_E4
                / _fetchTwapValue;
        }

        return _fetchTwapValue
            * PRECISION_FACTOR_E4
            / _answerUint256;
    }

    function _compareDifference(
        uint256 _relativeDifference
    )
        internal
        view
    {
        if (_relativeDifference > ALLOWED_DIFFERENCE) {
            revert OraclesDeviate();
        }
    }

    function _getChainlinkAnswer(
        address _tokenAddress
    )
        internal
        view
        returns (uint256)
    {
        (
            ,
            int256 answer,
            ,
            ,
        ) = priceFeed[_tokenAddress].latestRoundData();

        return uint256(
            answer
        );
    }

    function getETHPriceInUSD()
        public
        view
        returns (uint256)
    {
        (
            ,
            int256 answer,
            ,
            ,
        ) = ETH_PRICE_FEED.latestRoundData();

        return uint256(
            answer
        );
    }

    /**
    * @dev Retrieves the pool address for given
    * tokens and fee from Uniswap V3 Factory.
    */
    function _getPool(
        address _token0,
        address _token1,
        uint24 _fee
    )
        internal
        view
        returns (address pool)
    {
        return UNI_V3_FACTORY.getPool(
            _token0,
            _token1,
            _fee
        );
    }

    /**
    * @dev Validates if the given token address
    * is one of the two specified token addresses.
    */
    function _validateTokenAddress(
        address _tokenAddress,
        address _token0,
        address _token1
    )
        internal
        pure
    {
        if (_tokenAddress == ZERO_ADDRESS) {
            revert ZeroAddressNotAllowed();
        }

        if (_tokenAddress != _token0 && _tokenAddress != _token1) {
            revert TokenAddressMismatch();
        }
    }

    /**
    * @dev Validates if the given pool
    * address matches the expected pool address.
    */
    function _validatePoolAddress(
        address _pool,
        address _expectedPool
    )
        internal
        pure
    {
        if (_pool == ZERO_ADDRESS) {
            revert PoolDoesNotExist();
        }

        if (_pool != _expectedPool) {
            revert PoolAddressMismatch();
        }
    }

    /**
    * @dev Validates if the price feed for
    * a given token address is set.
    */
    function _validatePriceFeed(
        address _tokenAddress
    )
        internal
        view
    {
        if (priceFeed[_tokenAddress] == ZERO_FEED) {
            revert ChainLinkOracleNotSet();
        }
    }

    /**
    * @dev Validates if the TWAP oracle for
    * a given token address is already set.
    */
    function _validateTwapOracle(
        address _tokenAddress
    )
        internal
        view
    {
        if (uniTwapPoolInfo[_tokenAddress].oracle > ZERO_ADDRESS) {
            revert TwapOracleAlreadySet();
        }
    }

    /**
     * @dev Returns twapPrice by passing
     * the underlying token address.
     */
    function _getTwapPrice(
        address _tokenAddress,
        address _oracle
    )
        internal
        view
        returns (uint256)
    {
        return OracleLibrary.getQuoteAtTick(
            _getAverageTick(
                _oracle
            ),
            _getOneUnit(
                _tokenAddress
            ),
            _tokenAddress,
            WETH_ADDRESS
        );
    }

    function _getOneUnit(
        address _tokenAddress
    )
        internal
        view
        returns (uint128)
    {
        return uint128(
            10 ** _tokenDecimals[_tokenAddress]
        );
    }

    function _getAverageTick(
        address _oracle
    )
        internal
        view
        returns (int24)
    {
        uint32[] memory secondsAgo = new uint32[](
            2
        );

        secondsAgo[0] = TWAP_PERIOD;
        secondsAgo[1] = 0;

        (
            int56[] memory tickCumulatives
            ,
        ) = IUniswapV3Pool(_oracle).observe(
            secondsAgo
        );

        int56 twapPeriodInt56 = int56(
            int32(TWAP_PERIOD)
        );

        int56 tickCumulativesDelta = tickCumulatives[1]
            - tickCumulatives[0];

        int24 tick = int24(
            tickCumulativesDelta
            / twapPeriodInt56
        );

        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % twapPeriodInt56 != 0)) {
            tick--;
        }

        return tick;
    }

    /**
     * @dev Returns priceFeed decimals by
     * passing the underlying token address.
     */
    function decimals(
        address _tokenAddress
    )
        public
        view
        returns (uint8)
    {
        return priceFeed[_tokenAddress].decimals();
    }

    function _getTwapDerivatePrice(
        address _tokenAddress,
        UniTwapPoolInfo memory _uniTwapPoolInfo
    )
        internal
        view
        returns (uint256)
    {
        DerivativePartnerInfo memory partnerInfo = derivativePartnerTwap[
            _tokenAddress
        ];

        uint256 firstQuote = OracleLibrary.getQuoteAtTick(
            _getAverageTick(
                _uniTwapPoolInfo.oracle
            ),
            _getOneUnit(
                partnerInfo.partnerTokenAddress
            ),
            partnerInfo.partnerTokenAddress,
            WETH_ADDRESS
        );

        uint256 secondQuote = OracleLibrary.getQuoteAtTick(
            _getAverageTick(
                partnerInfo.partnerOracleAddress
            ),
            _getOneUnit(
                _tokenAddress
            ),
            _tokenAddress,
            partnerInfo.partnerTokenAddress
        );

        return firstQuote
            * secondQuote
            / uint256(
                _getOneUnit(
                    partnerInfo.partnerTokenAddress
                )
            );
    }

    /**
     * @dev Stores expected heartbeat
     * value for a pricing feed token.
     */
    function _recalibrate(
        address _tokenAddress
    )
        internal
    {
        heartBeat[_tokenAddress] = _recalibratePreview(
            _tokenAddress
        );
    }

    /**
     * @dev Check if chainLink feed was
     * updated within expected timeFrame
     * for single {_tokenAddress}.
     */
    function _chainLinkIsDead(
        address _tokenAddress
    )
        internal
        view
        returns (bool)
    {
        if (heartBeat[_tokenAddress] == 0) {
            revert HeartBeatNotSet();
        }

        uint80 latestRoundId = getLatestRoundId(
            _tokenAddress
        );

        uint256 upd = _getRoundTimestamp(
            _tokenAddress,
            latestRoundId
        );

        unchecked {
            upd = block.timestamp < upd
                ? block.timestamp
                : block.timestamp - upd;

            return upd > heartBeat[_tokenAddress];
        }
    }

    /**
     * @dev Recalibrates expected
     * heartbeat for a pricing feed.
     */
    function _recalibratePreview(
        address _tokenAddress
    )
        internal
        view
        returns (uint256)
    {
        uint80 latestRoundId = getLatestRoundId(
            _tokenAddress
        );

        uint256 latestTimestamp = _getRoundTimestamp(
            _tokenAddress,
            latestRoundId
        );

        uint80 iterationCount = _getIterationCount(
            latestRoundId
        );

        if (iterationCount < MIN_ITERATION_COUNT) {
            revert SampleTooSmall(
                {
                    size: iterationCount
                }
            );
        }

        uint80 i = 1;
        uint256 currentDiff;
        uint256 currentBiggest;
        uint256 currentSecondBiggest;

        while (i < iterationCount) {

            uint256 currentTimestamp = _getRoundTimestamp(
                _tokenAddress,
                latestRoundId - i
            );

            currentDiff = latestTimestamp
                - currentTimestamp;

            latestTimestamp = currentTimestamp;

            if (currentDiff >= currentBiggest) {

                currentSecondBiggest = currentBiggest;
                currentBiggest = currentDiff;

            } else if (currentDiff > currentSecondBiggest) {
                currentSecondBiggest = currentDiff;
            }

            unchecked {
                ++i;
            }
        }

        return currentSecondBiggest;
    }

    /**
     * @dev Determines number of iterations
     * needed during heartbeat recalibration.
     */
    function _getIterationCount(
        uint80 _latestAggregatorRoundId
    )
        internal
        pure
        returns (uint80 res)
    {
        res = _latestAggregatorRoundId < MAX_ROUND_COUNT
            ? _latestAggregatorRoundId
            : MAX_ROUND_COUNT;
    }

    /**
     * @dev Fetches timestamp of a byteshifted
     * aggregatorRound with specific _roundId.
     */
    function _getRoundTimestamp(
        address _tokenAddress,
        uint80 _roundId
    )
        internal
        view
        returns (uint256)
    {
        (
            ,
            ,
            ,
            uint256 timestamp
            ,
        ) = priceFeed[_tokenAddress].getRoundData(
                _roundId
            );

        return timestamp;
    }

    /**
     * @dev Routing latest round data from chainLink.
     * Returns latestRoundData by passing underlying token address.
     */
    function getLatestRoundId(
        address _tokenAddress
    )
        public
        view
        returns (
            uint80 roundId
        )
    {
        (
            roundId
            ,
            ,
            ,
            ,
        ) = priceFeed[_tokenAddress].latestRoundData();
    }
}
