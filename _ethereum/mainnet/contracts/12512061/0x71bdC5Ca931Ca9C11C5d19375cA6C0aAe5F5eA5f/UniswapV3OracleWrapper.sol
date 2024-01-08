// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./UtilsReady.sol";
import "./OracleLibrary.sol";
import "./SafeUint128.sol";

import "./ISimpleOracle.sol";
import "./IUniswapV3OracleWrapper.sol";

contract UniswapV3OracleWrapper is UtilsReady, ISimpleOracle, IUniswapV3OracleWrapper {
    uint32 public override period = 60; // 60 seconds

    constructor() UtilsReady() {}

    function setPeriod(uint32 _period) external onlyGovernor {
        require(_period > 0, "UniswapV3OracleWrapper::set-period:period-should-not-be-zero");
        period = _period;
    }

    function getAmountOut(
        address _pair, // uniswapv3 pool
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) external view override returns (uint256 _amountOut) {
        int256 twapTick = OracleLibrary.consult(_pair, period);
        return
            OracleLibrary.getQuoteAtTick(
                int24(twapTick), // can assume safe being result from consult()
                SafeUint128.toUint128(_amountIn),
                _tokenIn,
                _tokenOut
            );
    }
}
