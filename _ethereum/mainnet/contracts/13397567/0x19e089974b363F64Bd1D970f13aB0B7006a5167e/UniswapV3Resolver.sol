// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./GelatoString.sol";
import "./SUniswapV3.sol";
import "./IQuoter.sol";
import "./CUniswapV3.sol";
import "./Math.sol";
import "./CAaveServices.sol";

contract UniswapV3Resolver {
    using GelatoString for string;
    using Math for uint256;

    // should be called with callstatic of etherjs,
    // because quoteExactInputSingle is not a view function.
    function multicallGetAmountsOut(UniswapV3Data[] calldata datas_)
        public
        returns (UniswapV3Result[] memory results)
    {
        results = new UniswapV3Result[](datas_.length);

        for (uint256 i = 0; i < datas_.length; i++) {
            try this.getBestPool(datas_[i]) returns (
                UniswapV3Result memory result
            ) {
                results[i] = result;
            } catch Error(string memory error) {
                results[i] = UniswapV3Result({
                    id: datas_[i].id,
                    amountOut: 0,
                    fee: 0,
                    message: error.prefix(
                        "UniswapV3Resolver.getBestPool failed:"
                    )
                });
            } catch {
                results[i] = UniswapV3Result({
                    id: datas_[i].id,
                    amountOut: 0,
                    fee: 0,
                    message: "UniswapV3Resolver.getBestPool failed:undefined"
                });
            }
        }
    }

    function getBestPool(UniswapV3Data memory data_)
        public
        returns (UniswapV3Result memory)
    {
        uint256 amountOut = _quoteExactInputSingle(data_, LOW_FEES);
        uint24 fee = LOW_FEES;

        uint256 amountOutMediumFee;
        if (
            (amountOutMediumFee = _quoteExactInputSingle(data_, MEDIUM_FEES)) >
            amountOut
        ) {
            amountOut = amountOutMediumFee;
            fee = MEDIUM_FEES;
        }

        uint256 amountOutHighFee;
        if (
            (amountOutHighFee = _quoteExactInputSingle(data_, HIGH_FEES)) >
            amountOut
        ) {
            amountOut = amountOutHighFee;
            fee = HIGH_FEES;
        }

        return
            UniswapV3Result({
                id: data_.id,
                amountOut: amountOut,
                fee: fee,
                message: OK
            });
    }

    function _quoteExactInputSingle(UniswapV3Data memory data_, uint24 fee_)
        internal
        returns (uint256)
    {
        return
            IQuoter(QUOTER).quoteExactInputSingle(
                data_.tokenIn,
                data_.tokenOut,
                fee_,
                data_.amountIn,
                0
            );
    }
}
