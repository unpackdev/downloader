pragma solidity >=0.7.0;

import "./FullMath.sol";
import "./IUniswapV3Pool.sol";
import "./LiquidityAmounts.sol";

contract LiquidityQuoter is LiquidityAmounts {  
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) public pure returns (uint256) {
        return FullMath.mulDiv(a, b, denominator);
    }
}