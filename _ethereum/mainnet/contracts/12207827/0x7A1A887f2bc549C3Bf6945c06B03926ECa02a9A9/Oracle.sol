// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./SafeMath.sol";

import "./IUniswapV2Pair.sol"; // source of pricing for wbtc, lfbtc, lift
import "./IUniswapV2Factory.sol";
import "./IIdeaFund.sol"; // source of pricing for CTRL
import "./IHedgeFund.sol"; // source of pricing for HAIF
import "./ILinkOracle.sol"; // LINK


import "./Babylonian.sol";
import "./FixedPoint.sol";
import "./UniswapV2Library.sol";
import "./UniswapV2OracleLibrary.sol";
import "./Epoch.sol";


// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract Oracle is Epoch {
    using FixedPoint for *;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // uniswap
    address public staking; // wbtc
    address public peg; // lfbtc
    address public share; // lift
    address public control; // ctrl
    address public hedge; // haif
    address public hedgefund; // hedgefund
    address public ideafund; // idea fund
    address public factory;

    IUniswapV2Pair public pairStakingtoPeg;
    IUniswapV2Pair public pairPegtoShare;
    ILinkOracle public linkOracle;

    // oracle
    uint32 public blockTimestampLast;
    uint256 public priceStakingCumulativeLast;
    uint256 public pricePegCumulativeLast;
    uint256 public priceShareCumulativeLast;

    uint public priceStakingAverage;
    uint public pricePegAverage;
    uint public priceShareAverage;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _factory,
        address _staking, //wbtc
        address _peg, // lfbtc
        address _share, // lift
        address _control, // ctrl
        address _hedge, // haif
        address _hedgefund,
        address _ideafund,
        ILinkOracle _linkOracle,
        uint256 _period,
        uint256 _startTime
    ) Epoch(_period, _startTime, 0) {

        hedgefund = _hedgefund;
        ideafund = _ideafund;
        hedge = _hedge;
        control = _control;
        linkOracle = _linkOracle;

        peg = _peg;
        share = _share;
        staking = _staking;
        factory = _factory;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function initialize() external onlyOperator
    {
        pairStakingtoPeg = IUniswapV2Pair(
            UniswapV2Library.pairFor(factory, staking, peg)
        );
       
        pairPegtoShare = IUniswapV2Pair(
            UniswapV2Library.pairFor(factory, peg, share)
        );
       
       // pairStakingtoPeg.token0 = LFBTC (PEG)
       // pairStakingToPeg.token1 = WBTC (STAKING)
       // pairStakingtoShare.token0 = LIFT (SHARE)
       // pairStakingtoShare.token1 = LFBTC (PEG)

        pricePegCumulativeLast = pairStakingtoPeg.price0CumulativeLast(); // fetch the current accumulated price value (0 / 1)
        priceStakingCumulativeLast = pairStakingtoPeg.price1CumulativeLast(); // fetch the current accumulated price value (1 / 0)
        priceShareCumulativeLast = pairPegtoShare.price0CumulativeLast();
    }

    /** @dev Updates 1-day EMA price from Uniswap.  */
    function update() external checkEpoch {
        (
            uint256 pricePegCumulative,
            uint256 priceStakingCumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairStakingtoPeg));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        (uint256 priceShareCumulative,,) = UniswapV2OracleLibrary.currentCumulativePrices(address(pairPegtoShare));

        if (timeElapsed == 0) {
            // prevent divided by zero
            return;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        priceStakingAverage = uint(FixedPoint.uq112x112(
            uint224((priceStakingCumulative - priceStakingCumulativeLast) / timeElapsed)
        ).mul(1e18).decode144());
        pricePegAverage = uint(FixedPoint.uq112x112(
            uint224((pricePegCumulative - pricePegCumulativeLast) / timeElapsed)
        ).mul(1e18).decode144());
        priceShareAverage = uint(FixedPoint.uq112x112(
            uint224((priceShareCumulative - priceShareCumulativeLast) / timeElapsed)
        ).mul(1e18).decode144());

        priceStakingCumulativeLast = priceStakingCumulative;
        pricePegCumulativeLast = pricePegCumulative;
        priceShareCumulativeLast = priceShareCumulative;
        blockTimestampLast = blockTimestamp;

        emit Updated(priceStakingCumulative, pricePegCumulative, priceShareCumulative);
    }

    function wbtcPriceOne() external view returns(uint256) {
        return uint256(linkOracle.latestAnswer() * 1e10);
    }

    // no idea if this does what I want...
    function priceOf(address token) external view returns (uint256 price) {
         if (token == peg) {
            return pricePegAverage;
        } else if (token == share) {
            return priceShareAverage;
        } else if (token == control) {
            IIdeaFund(token).controlPrice();
        } else if(token == hedge) {
            IHedgeFund(token).hedgePrice();
        }
    }

    function pairFor(
        address _factory,
        address _tokenA,
        address _tokenB
    ) external view returns (address lpt) {
        return UniswapV2Library.pairFor(_factory, _tokenA, _tokenB);
    }

    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast, uint256 price2CumulativeLast);
}