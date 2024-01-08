//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "./Ownable.sol";
import "./OracleLibrary.sol";
import "./IUniswapV3Pool.sol";
import "./IPriceProvider.sol";
import "./IERC20.sol";

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);
}

contract UniswapPriceProvider is Ownable, IPriceProvider {
     uint32 public period = 600; // 600 seconds
     struct TokensInfo {
        address quoteAddr;
        IERC20Extented base;
        IERC20Extented quote;
        uint8 baseDecimals;
        uint8 quoteDecimals;
    }
    
    function setPeriod(uint32 _period) external onlyOwner {
        require(_period > 0, "should be not zero");
        period = _period;
    }

    function getPairPrice(
        address pair,
        address base
    ) override external view returns (uint256 price) {
        IUniswapV3Pool pool = IUniswapV3Pool(pair);
        int24 tick = OracleLibrary.consult(pair, period);
        address token0 = pool.token0();
        address token1 = pool.token1();
        TokensInfo memory info;
        info.base = IERC20Extented(base);
        info.baseDecimals = info.base.decimals();
        uint128 amount;
        if (info.baseDecimals != 18) {
            amount = uint128(1e18 * (10**(18 - info.baseDecimals)));
        }
        else{
            amount = uint128(1e18);
        }
        if (base == token0) {
            info.quoteAddr = token1;
        } else {
            info.quoteAddr = token0;
        }

        uint256 priceInBase = 
            OracleLibrary.getQuoteAtTick(tick, amount, info.quoteAddr, base);
        info.quote = IERC20Extented(info.quoteAddr);
        info.quoteDecimals = info.quote.decimals();
        if (info.quoteDecimals != 18) {
            priceInBase = priceInBase / (10**(18 - info.quoteDecimals));
        }
        return priceInBase;
    }

}
