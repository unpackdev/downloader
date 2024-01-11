// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./BP.sol";
import "./UniswapV2Library.sol";

/// @title Uniswap V2 price impact library
/// @notice Provides list of helper functions to calculate price impact
library UniswapV2PriceImpactLibrary {
    /// @notice Returns difference between prices before and after swap
    /// @param _factory Uniswap V2 Factory
    /// @param _input Input amount
    /// @param _path List of tokens, that will be used to compose pairs for chained getAmountOut calculations
    /// @return Difference between prices before and after swap
    function calculatePriceImpactInBP(
        address _factory,
        uint _input,
        address[] calldata _path
    ) internal view returns (uint) {
        require(_path.length >= 2, "UniswapV2Library: INVALID_PATH");

        uint amountOutput = _input;
        uint quotedOutput = _input;

        uint pLength = _path.length - 1;
        for (uint i; i < pLength; ) {
            (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(_factory, _path[i], _path[i + 1]);
            amountOutput = UniswapV2Library.getAmountOut(amountOutput, reserveIn, reserveOut);
            quotedOutput = (quotedOutput * reserveOut) / reserveIn;

            unchecked {
                i = i + 1;
            }
        }

        return ((quotedOutput - amountOutput) * BP.DECIMAL_FACTOR) / quotedOutput;
    }
}
