// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";

import "./IUniswapV2Pair.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UsingBaseOracle.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/* ICHISpotOracleUSDUniswap returns the price of ICHI
* It requires a chainlink oracle to get from paired Liquidity token to USD
* example  ICHI/ETH pair requires a ETH/USD chainlink
* assumes 50/50 weighted Liquidity pair pool
*/
contract ICHISpotOracleUSDUniswap is UsingBaseOracle {
    using SafeMath for uint256;

    address public ICHI = 0x903bEF1736CDdf2A537176cf3C64579C3867A881;

    uint256 constant PERCISION = 18;

    function getICHIPrice(address pair_, address chainlink_) external view override returns (uint256 price) {
        IUniswapV2Pair _pair = IUniswapV2Pair(pair_);
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, ) = _pair.getReserves();
        uint eth_usd = getChainLinkPrice(chainlink_);
        uint chainlink_decimals = AggregatorV3Interface(chainlink_).decimals();
        if (chainlink_decimals < PERCISION) {
            eth_usd = eth_usd.mul(10 ** (PERCISION - chainlink_decimals));
        }
        if (_pair.token0() == ICHI) {
            uint ichi_reserve = reserve0 * 10**9;
            uint eth_reserve = reserve1;
            price = eth_usd.mul(eth_reserve).div(ichi_reserve);

        } else if (_pair.token1() == ICHI) {
            uint ichi_reserve = reserve1 * 10**9;
            uint eth_reserve = reserve0;
            price = eth_usd.mul(eth_reserve).div(ichi_reserve);
        } else {
            price = 0;
        }
    }

    function getBaseToken() external view override returns (address token) {
        token = ICHI;
    }

    function decimals() external view override returns (uint256) {
        return PERCISION;
    }

    function getChainLinkPrice(address chainlink_) public view returns (uint256 price) {

        (
            , 
            int256 price_,
            ,
            ,
            
        ) = AggregatorV3Interface(chainlink_).latestRoundData();
        price = uint256(price_);
    }



}