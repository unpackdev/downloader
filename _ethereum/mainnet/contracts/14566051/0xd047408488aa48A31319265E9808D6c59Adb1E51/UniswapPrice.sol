//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./P.sol";
import "./LibHelpers.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract UniswapPrice {

    using SafeMath for uint256;

    //-------------------------------------------------------------------------------------------------------------------
    // Mainnet
    address private constant USDC_ETH_ADDRESS = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address private constant ETH_BEAN_ADDRESS = 0x87898263B6C5BABe34b4ec53F22d98430b91e371;
    address[2] private TOKENS = [0xDC59ac4FeFa32293A95889Dc396682858d52e5Db, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2];
    //-------------------------------------------------------------------------------------------------------------------
    // Ropsten
    // address private constant USDC_ETH_ADDRESS = 0x681A4164703351d6AceBA9D7038b573b444d3353;
    // address private constant ETH_BEAN_ADDRESS = 0x298c5f1f902c5bDc2936eb44b3E0E8675F40B8db;
    // address[2] private TOKENS = [0xDC59ac4FeFa32293A95889Dc396682858d52e5Db, 0xc778417E063141139Fce010982780140Aa0cD5Ab];
    //-------------------------------------------------------------------------------------------------------------------
    
    function getUniswap() public view returns (P.Pool memory pool) {
        pool.pool = ETH_BEAN_ADDRESS;
        pool.tokens = TOKENS;
        // Bean, Eth
        uint256[2] memory reserves = _reserves();
        pool.balances = reserves;
        // USDC, Eth
        uint256[2] memory pegReserves = _pegReserves();

        uint256[2] memory prices = getUniswapPrice(reserves, pegReserves);
        pool.price = prices[0];
        pool.liquidity = getUniswapUSDValue(reserves, prices);
        pool.deltaB = getUniswapDeltaB(reserves, pegReserves);
    }
    
    function getUniswapPrice(uint256[2] memory reserves, uint256[2] memory pegReserves) private pure returns (uint256[2] memory prices) {
        prices[1] = uint256(pegReserves[0]).mul(1e18).div(pegReserves[1]);
        prices[0] = reserves[1].mul(prices[1]).div(reserves[0]).div(1e12);
    }

    function getUniswapUSDValue(uint256[2] memory balances, uint256[2] memory rates) private pure returns (uint) {
        return (balances[0].mul(rates[0]) + balances[1].mul(rates[1]).div(1e12)).div(1e6);
    }

    function getUniswapDeltaB(uint256[2] memory reserves, uint256[2] memory pegReserves) private pure returns (int256) {
        uint256 newBeans = LibHelpers.sqrt(reserves[1].mul(reserves[0]).mul(pegReserves[0]).div(pegReserves[1]));
        return int256(newBeans) - int256(reserves[0]);
    }

    function _reserves() private view returns (uint256[2] memory reserves) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(ETH_BEAN_ADDRESS).getReserves();
        reserves = [uint256(reserve1), uint256(reserve0)];
    }

    function _pegReserves() private view returns (uint256[2] memory reserves) {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(USDC_ETH_ADDRESS).getReserves();
        reserves = [uint256(reserve0), uint256(reserve1)];
    }

    function sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}