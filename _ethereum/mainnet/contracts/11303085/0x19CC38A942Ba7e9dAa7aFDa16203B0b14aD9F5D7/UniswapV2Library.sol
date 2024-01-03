// taken from here: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
pragma solidity >=0.5.0;

import "./SafeMath.sol";


library UniswapV2Library {
    using SafeMath for uint256;

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /**
     * @author allemanfredi
     * @notice given an input amount, returns the output
     *         amount with slippage and with fees. This fx is
     *         to check approximately onchain the slippage
     *         during a swap
     */
    function calculateSlippageAmountWithFees(
        uint256 _amountIn,
        uint256 _allowedSlippage,
        uint256 _rateIn,
        uint256 _rateOut
    ) internal pure returns (uint256) {
        require(_amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        uint256 slippageAmount = _amountIn
            .mul(_rateOut)
            .div(_rateIn)
            .mul(10000 - _allowedSlippage)
            .div(10000);
        // NOTE: remove fees
        return slippageAmount.mul(997).div(1000);
    }

    /**
     * @author allemanfredi
     * @notice given 2 inputs amount, it returns the
     *         rate percentage between the 2 amounts
     */
    function calculateRate(uint256 _amountIn, uint256 _amountOut) internal pure returns (uint256) {
        require(_amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(_amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        return
            _amountIn > _amountOut
                ? (10000 * _amountIn).sub(10000 * _amountOut).div(_amountIn)
                : (10000 * _amountOut).sub(10000 * _amountIn).div(_amountOut);
    }

    /**
     * @author allemanfredi
     * @notice returns the slippage for a trade without counting the fees
     */
    function calculateSlippage(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) internal pure returns (uint256) {
        require(_amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        uint256 price = _reserveOut.mul(10**18).div(_reserveIn);
        uint256 quote = _amountIn.mul(price);
        uint256 amountOut = getAmountOut(_amountIn, _reserveIn, _reserveOut);
        return uint256(10000).sub((amountOut * 10000).div(quote.div(10**18))).mul(997).div(1000);
    }
}
