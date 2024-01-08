// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./GelatoString.sol";
import "./SUniswap.sol";
import "./IUniswapV2Router02.sol";
import "./CUniswap.sol";
import "./CAaveServices.sol";

contract UniswapResolver {
    using GelatoString for string;

    function multicallGetAmounts(UniswapData[] memory _datas)
        public
        view
        returns (UniswapResult[] memory)
    {
        UniswapResult[] memory results = new UniswapResult[](_datas.length);

        for (uint256 i = 0; i < _datas.length; i++) {
            try
                IUniswapV2Router02(UNISWAPV2ROUTER02).getAmountsOut(
                    _datas[i].amountIn,
                    _datas[i].path
                )
            returns (uint256[] memory amounts) {
                results[i] = UniswapResult({
                    id: _datas[i].id,
                    amountOut: amounts[_datas[i].path.length - 1],
                    message: OK
                });
            } catch Error(string memory error) {
                results[i] = UniswapResult({
                    id: _datas[i].id,
                    amountOut: 0,
                    message: error.prefix(
                        "UniswapResolver.getAmountOut failed:"
                    )
                });
            } catch {
                results[i] = UniswapResult({
                    id: _datas[i].id,
                    amountOut: 0,
                    message: "UniswapResolver.getAmountOut failed:undefined"
                });
            }
        }

        return results;
    }
}
