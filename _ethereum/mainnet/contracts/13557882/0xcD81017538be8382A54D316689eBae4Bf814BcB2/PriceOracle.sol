pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./FixedPoint96.sol";

interface IHypervisor {

    function pool() external view returns(address);

    function getTotalAmounts() external view returns (uint256, uint256);

    function totalSupply() external view returns (uint256);
}

contract PriceOracle {
    using SafeMath for uint256;
    constructor() {}

    function visorPrice(IHypervisor _hypervisor, uint32 interval) external view returns (uint256){
        uint256 totalSupply = _hypervisor.totalSupply();
        (uint256 token0, uint256 token1) = _hypervisor.getTotalAmounts();
        uint256 priceX96 = getPriceX96FromSqrtPriceX96(getSqrtTwapX96(_hypervisor.pool(), interval)); // 24 hours
        return token0.div(totalSupply).mul(priceX96).add(token1.div(totalSupply));
    }

    function getSqrtTwapX96(address uniswapV3Pool, uint32 twapInterval) public view returns (uint160 sqrtPriceX96) {
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (sqrtPriceX96, , , , , , ) = IUniswapV3Pool(uniswapV3Pool).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / twapInterval)
            );
        }
    }

    function getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) public pure returns(uint256 priceX96) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }
}
