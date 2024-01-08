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
    address public stakingbtc; // wbtc
    address public stakingeth; // weth
    address public pegbtc; // lfbtc
    address public pegeth; // lfeth
    address public share; // lift
    address public control; // ctrl
    address public hedge; // haif
    address public hedgefund; // hedgefund
    address public ideafund; // idea fund
    address public factory;

    IUniswapV2Pair public pairStakingBTCtoPegbtc;
    IUniswapV2Pair public pairStakingETHtoPegeth;
    IUniswapV2Pair public pairPegbtctoShare;
    ILinkOracle public linkBTCOracle;
    ILinkOracle public linkETHOracle;


    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _factory,
        address _stakingbtc, //wbtcPriceOne
        address _stakingeth, //wethPriceOne
        address _pegbtc, // lfbtc
        address _pegeth, // lfeth
        address _share, // lift
        address _control, // ctrl
        address _hedge, // haif
        address _hedgefund,
        address _ideafund,
        ILinkOracle _linkOracleBTC,
        ILinkOracle _linkOracleETH
    ) {

        hedgefund = _hedgefund;
        ideafund = _ideafund;
        hedge = _hedge;
        control = _control;
        linkBTCOracle = _linkOracleBTC;
        linkETHOracle = _linkOracleETH;

        pegbtc = _pegbtc;
        pegeth = _pegeth;
        share = _share;
        stakingbtc = _stakingbtc;
        stakingeth = _stakingeth;
        factory = _factory;

        pairStakingBTCtoPegbtc = IUniswapV2Pair(
            UniswapV2Library.pairFor(factory, stakingbtc, pegbtc)
        );

        pairStakingETHtoPegeth = IUniswapV2Pair(
            UniswapV2Library.pairFor(factory, stakingeth, pegeth)  
        );
       
        pairPegbtctoShare = IUniswapV2Pair(
            UniswapV2Library.pairFor(factory, pegbtc, share)
        );
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function wbtcPriceOne() external view returns(uint256) {
        return uint256(linkBTCOracle.latestAnswer() * 1e10);
    }

    function wethPriceOne() external view returns(uint256) {
        return uint256(linkETHOracle.latestAnswer() * 1e10);
    }

    function priceOf(address token) external view returns (uint256 price) {
        return _priceOf(token);
    }

    function _priceOf(address token) internal view returns (uint256 price) {
        if (token == pegbtc) {
            return priceFromPair(pairStakingBTCtoPegbtc);
        } else if (token == pegeth) {
            return priceFromPair(pairStakingETHtoPegeth);
        } else if (token == share) {
            return priceFromPair(pairPegbtctoShare);
        } else if (token == control) {
            return IIdeaFund(ideafund).getControlPrice();
        } else if(token == hedge) {
            return IHedgeFund(hedgefund).hedgePrice();
        } else if(token == stakingbtc) {
            return uint256(linkBTCOracle.latestAnswer() * 1e10);
        } else if (token == stakingeth) {
            return uint256(linkETHOracle.latestAnswer() * 1e10);
        }
    }

    // always returns the price for token1 
    function priceFromPair(IUniswapV2Pair pair) public view returns (uint256 price) {
        uint256 token0Supply = 0;
        uint256 token1Supply = 0;

        (token0Supply, token1Supply, ) = pair.getReserves();

        if (pair.token0() == stakingbtc) {
            token0Supply = token0Supply.mul(1e18);
                     
            return token0Supply.div(token1Supply).mul(_priceOf(pair.token0())).div(1e8);
        } else if (pair.token1() == stakingbtc) {
            token1Supply = token1Supply.mul(1e18);

            return token1Supply.div(token0Supply).mul(_priceOf(pair.token1())).div(1e8);
        } else if (pair.token0() == stakingeth) {
            token0Supply = token0Supply.mul(1e8);

            return token0Supply.div(token1Supply).mul(_priceOf(pair.token0())).div(1e8);
        }else if (pair.token1() == stakingeth) {
            token1Supply = token1Supply.mul(1e18);

            return token1Supply.div(token0Supply).mul(_priceOf(pair.token1())).div(1e8);
        }else if (pair.token0() == pegbtc) {
            token0Supply = token0Supply.mul(1e8);

            return token0Supply.div(token1Supply).mul(_priceOf(pair.token0())).div(1e8);

        } else if (pair.token1() == pegbtc) {                    
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