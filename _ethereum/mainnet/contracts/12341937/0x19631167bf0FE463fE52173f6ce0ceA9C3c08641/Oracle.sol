// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

//Contract deployed by LK Tech Club Incubator 2021 dba Lift.Kitchen - 4/24/2021

import "./SafeMath.sol";

import "./IUniswapV2Pair.sol"; // source of pricing for wbtc, lfbtc, lift
import "./IUniswapV2Factory.sol";
import "./IIdeaFund.sol"; // source of pricing for CTRL
import "./IHedgeFund.sol"; // source of pricing for HAIF
import "./ILinkOracle.sol"; // LINK


import "./Babylonian.sol";
import "./FixedPoint.sol";
import "./UniswapV2Library.sol";

import "./Operator.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract Oracle is Operator {
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
        ILinkOracle _linkOracle
    ) {

        hedgefund = _hedgefund;
        ideafund = _ideafund;
        hedge = _hedge;
        control = _control;
        linkOracle = _linkOracle;

        peg = _peg;
        share = _share;
        staking = _staking;
        factory = _factory;

        pairStakingtoPeg = IUniswapV2Pair(
            UniswapV2Library.pairFor(factory, staking, peg)
        );
       
        pairPegtoShare = IUniswapV2Pair(
            UniswapV2Library.pairFor(factory, peg, share)
        );
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function wbtcPriceOne() external view returns(uint256) {
        return uint256(linkOracle.latestAnswer() * 1e10);
    }

    function priceOf(address token) external view returns (uint256 price) {
        return _priceOf(token);
    }

    function _priceOf(address token) internal view returns (uint256 price) {
         if (token == peg) {
            return priceFromPair(pairStakingtoPeg);
        } else if (token == share) {
            return priceFromPair(pairPegtoShare);
        } else if (token == control) {
            return IIdeaFund(ideafund).getControlPrice();
        } else if(token == hedge) {
            return IHedgeFund(hedgefund).hedgePrice();
        } else if(token == staking) {
            return uint256(linkOracle.latestAnswer() * 1e10);
        }
    }

    // always returns the price for token1 
    function priceFromPair(IUniswapV2Pair pair) public view returns (uint256 price) {
        uint256 token0Supply = 0;
        uint256 token1Supply = 0;

        (token0Supply, token1Supply, ) = pair.getReserves();

        if (pair.token0() == staking) {
            token0Supply = token0Supply.mul(1e18);
                     
            return token0Supply.div(token1Supply).mul(_priceOf(pair.token0())).div(1e8);
        } else if (pair.token1() == staking) {
            token1Supply = token1Supply.mul(1e18);

            return token1Supply.div(token0Supply).mul(_priceOf(pair.token1())).div(1e8);

        } else if (pair.token0() == peg) {
            token0Supply = token0Supply.mul(1e8);

            return token0Supply.div(token1Supply).mul(_priceOf(pair.token0())).div(1e8);

        } else if (pair.token1() == peg) {                    
            token1Supply = token1Supply.mul(1e8);

            return token1Supply.div(token0Supply).mul(_priceOf(pair.token1())).div(1e8);
        }
    }

    function updateHedgeFund(address newHedgeFund) external onlyOperator {
        hedgefund = newHedgeFund;
    }

    function updateIdeaFund(address newIdeaFund) external onlyOperator {
        ideafund = newIdeaFund;
    }

    function pairFor(
        address _factory,
        address _tokenA,
        address _tokenB
    ) external view returns (address lpt) {
        return UniswapV2Library.pairFor(_factory, _tokenA, _tokenB);
    }
}