// SPDX-License-Identifier: GNU

/// @notice adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol

pragma solidity 0.7.6;

import "./OracleCommon.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";

/**
 @notice A oracle that uses 2 TWAP periods and uses the lower of the 2 values.  
 Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period,
 Periodicity is fixed at deployment time. Index (usually USD) token is fixed at deployment time.
 A single deployment can be shared by multiple oneToken clients and can observe multiple base tokens.
 Non-USD index tokens are possible. Such deployments can used as interim oracles in Composite Oracles. They should
 NOT be registered because they are not, by definition, valid sources of USD quotes.  
 Example calculation MPH/ETH -> ETH/USD 1hr and MPH/ETH -> ETH/USD 24hr take the lower value and return.  This is a safety net to help 
 prevent price manipulation.  This oracle combines 2 TWAPs to save on gas for keeping seperate oracles for these 2 PERIODS.
 */

contract UniswapOracleTWAPCompare is OracleCommon {
    using FixedPoint for *;
    using SafeMath for uint256;

    uint256 public immutable PERIOD_1;
    uint256 public immutable PERIOD_2;

    address public immutable uniswapFactory;

    struct Pair {
        address token0;
        address token1;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        uint32  blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    mapping(address => Pair) period_1_pairs;
    mapping(address => Pair) period_2_pairs;

    /**
     @notice the indexToken (index token), averaging period and uniswapfactory cannot be changed post-deployment
     @dev deploy multiple instances to support different configurations
     @param oneTokenFactory_ oneToken factory to bind to
     @param uniswapFactory_ external factory contract needed by the uniswap library
     @param indexToken_ the index token to use for valuations. If not a usd collateral token then the Oracle should not be registered in the factory but it can be used by CompositeOracles.
     @param period_1_ the averaging period to use for price smoothing
     @param period_2_ the averaging period to use for price smoothing
     */
    constructor(address oneTokenFactory_, address uniswapFactory_, address indexToken_, uint256 period_1_, uint256 period_2_)
        OracleCommon(oneTokenFactory_, "ICHI TWAP Compare Uniswap Oracle", indexToken_)
    {
        require(uniswapFactory_ != NULL_ADDRESS, "UniswapOracleTWAPCompare: uniswapFactory cannot be empty");
        require(period_1_ > 0, "UniswapOracleTWAPCompare: period must be > 0");
        require(period_2_ > 0, "UniswapOracleTWAPCompare: period must be > 0");
        uniswapFactory = uniswapFactory_;
        PERIOD_1 = period_1_;
        PERIOD_2 = period_2_;
        indexToken = indexToken_;
    }

    /**
     @notice configures parameters for a pair, token versus indexToken
     @dev initializes the first time, then does no work. Initialized from the Factory when assigned to an asset.
     @param token the base token. index is established at deployment time and cannot be changed
     */
    function init(address token) external onlyModuleOrFactory override {
        require(token != NULL_ADDRESS, "UniswapOracleTWAPCompare: token cannot be null");
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        // this condition should never be false
        require(address(_pair) != NULL_ADDRESS, "UniswapOracleTWAPCompare: unknown pair");
        Pair storage p1 = period_1_pairs[address(_pair)];
        Pair storage p2 = period_2_pairs[address(_pair)];
        if(p1.token0 == NULL_ADDRESS && p2.token0 == NULL_ADDRESS) {
            p1.token0 = _pair.token0();
            p2.token0 = _pair.token0();
            p1.token1 = _pair.token1();
            p2.token1 = _pair.token1();
            p1.price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
            p2.price0CumulativeLast = _pair.price0CumulativeLast();
            p1.price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
            p2.price1CumulativeLast = _pair.price1CumulativeLast();
            uint112 reserve0;
            uint112 reserve1;
            (reserve0, reserve1, p1.blockTimestampLast) = _pair.getReserves();
            p2.blockTimestampLast = p1.blockTimestampLast;
            require(reserve0 != 0 && reserve1 != 0, 'UniswapOracleTWAPCompare: NO_RESERVES'); // ensure that there's liquidity in the pair
            emit OracleInitialized(msg.sender, token, indexToken);
        }
    }

    /**
     @notice returns equivalent indexTokens for amountIn, token
     @dev index token is established at deployment time
     @param token ERC20 token
     @param amountTokens quantity, token precision
     @param amountUsd US dollar equivalent, precision 18
     @param volatility metric for future use-cases 
     */
    function read(address token, uint256 amountTokens) external view override returns(uint256 amountUsd, uint256 volatility) {
        amountUsd = tokensToNormalized(indexToken, consult(token, amountTokens));
        volatility = 1;
    }

    /**
     @notice returns equivalent baseTokens for amountUsd, indexToken
     @dev index token is established at deployment time
     @param token ERC20 token
     @param amountTokens quantity, token precision
     @param amountUsd US dollar equivalent, precision 18
     @param volatility metric for future use-cases
     */
    function amountRequired(address token, uint256 amountUsd) external view override returns(uint256 amountTokens, uint256 volatility) {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        Pair storage p1 = period_1_pairs[address(_pair)];
        Pair storage p2 = period_2_pairs[address(_pair)];
        require(token == p1.token0 || token == p1.token1, 'UniswapOracleTWAPCompare: INVALID_TOKEN');
        require(p1.price0CumulativeLast > 0 && p2.price0CumulativeLast > 0, "UniswapOracleTWAPCompare: Gathering history. Try again later");
        amountUsd = normalizedToTokens(indexToken, amountUsd);
        uint256 p1Tokens = (token == p1.token0 ? p1.price0Average : p1.price1Average).reciprocal().mul(amountUsd).decode144();
        uint256 p2Tokens = (token == p2.token0 ? p2.price0Average : p2.price1Average).reciprocal().mul(amountUsd).decode144();
        if (p1Tokens > p2Tokens) {  //want to take the lower price which is more larger amount of tokens
            amountTokens = p1Tokens;
        } else {
            amountTokens = p2Tokens;
        }
        volatility = 1;
    }

    /**
     @notice updates price observation history, if necessary
     @dev it is permissible for anyone to supply gas and update the oracle's price history.
     @param token baseToken to update
     */
    function update(address token) external override {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        Pair storage p1 = period_1_pairs[address(_pair)];
        Pair storage p2 = period_2_pairs[address(_pair)];
        if(p1.token0 != NULL_ADDRESS) {
            (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
                UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
            uint32 timeElapsed_1 = blockTimestamp - p1.blockTimestampLast; // overflow is desired
            uint32 timeElapsed_2 = blockTimestamp - p2.blockTimestampLast; // overflow is desired

            // ensure that at least one full period has passed since the last update
            ///@ dev require() was dropped in favor of if() to make this safe to call when unsure about elapsed time

            if(timeElapsed_1 >= PERIOD_1 || p1.price0Average.mul(PRECISION).decode144() == 0) {
                // overflow is desired, casting never truncates
                // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
                p1.price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - p1.price0CumulativeLast) / timeElapsed_1));
                p1.price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - p1.price1CumulativeLast) / timeElapsed_1));

                p1.price0CumulativeLast = price0Cumulative;
                p1.price1CumulativeLast = price1Cumulative;
                p1.blockTimestampLast = blockTimestamp;
            }
            if(timeElapsed_2 >= PERIOD_2 || p2.price0Average.mul(PRECISION).decode144() == 0) {
                // overflow is desired, casting never truncates
                // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
                p2.price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - p2.price0CumulativeLast) / timeElapsed_2));
                p2.price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - p2.price1CumulativeLast) / timeElapsed_2));

                p2.price0CumulativeLast = price0Cumulative;
                p2.price1CumulativeLast = price1Cumulative;
                p2.blockTimestampLast = blockTimestamp;
            }
            // No event emitter to save gas
        }
    }

    // note this will always return 0 before update has been called successfully for the first time.
    // this will return an average over a long period of time unless someone calls the update() function.
    
    /**
     @notice returns equivalent indexTokens for amountIn, token
     @dev always returns 0 before update(token) has been called successfully for the first time.
     @param token baseToken to update
     @param amountTokens amount in token native precision
     @param amountOut anount in tokens, reciprocal token
     */
    function consult(address token, uint256 amountTokens) public view returns (uint256 amountOut) {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        Pair storage p1 = period_1_pairs[address(_pair)];
        Pair storage p2 = period_2_pairs[address(_pair)];
        require(token == p1.token0 || token == p1.token1, 'UniswapOracleTWAPCompare: INVALID_TOKEN');
        require(p1.price0CumulativeLast > 0 && p2.price0CumulativeLast > 0, "UniswapOracleTWAPCompare: Gathering history. Try again later");
        uint256 p1Out = (token == p1.token0 ? p1.price0Average : p1.price1Average).mul(amountTokens).decode144();
        uint256 p2Out = (token == p2.token0 ? p2.price0Average : p2.price1Average).mul(amountTokens).decode144();
        if (p1Out > p2Out) {
            amountOut = p2Out;
        } else {
            amountOut = p1Out;
        }
    }

    /**
     @notice discoverable internal state. Returns pair info for period 1
     @param token baseToken to inspect
     */
    function pair1Info(address token) external view
        returns
    (
        address token0,
        address token1,
        uint256 price0CumulativeLast,
        uint256 price1CumulativeLast,
        uint256 price0Average,
        uint256 price1Average,
        uint32  blockTimestampLast,
        uint256 period
    )
    {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        Pair storage p = period_1_pairs[address(_pair)];
        return(
            p.token0,
            p.token1,
            p.price0CumulativeLast,
            p.price1CumulativeLast,
            p.price0Average.mul(PRECISION).decode144(),
            p.price1Average.mul(PRECISION).decode144(),
            p.blockTimestampLast,
            PERIOD_1
        );
    }

    /**
     @notice discoverable internal state. Returns pair info for period 2
     @param token baseToken to inspect
     */
    function pair2Info(address token) external view
        returns
    (
        address token0,
        address token1,
        uint256 price0CumulativeLast,
        uint256 price1CumulativeLast,
        uint256 price0Average,
        uint256 price1Average,
        uint32  blockTimestampLast,
        uint256 period
    )
    {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(uniswapFactory, token, indexToken));
        Pair storage p = period_2_pairs[address(_pair)];
        return(
            p.token0,
            p.token1,
            p.price0CumulativeLast,
            p.price1CumulativeLast,
            p.price0Average.mul(PRECISION).decode144(),
            p.price1Average.mul(PRECISION).decode144(),
            p.blockTimestampLast,
            PERIOD_2
        );
    }

}