// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IUniswapOracleV3.sol";
import "./OracleLibrary.sol";
import "./IUniswapV3Factory.sol";

contract UniswapOracleV3 is IUniswapOracleV3 {
    uint256 public constant override PERIOD = 60 * 60; // in seconds
    address public immutable override factory;
    uint24 public constant DEFAULT_FEE = 3000; // pool 0.3% fee // best for most pairs
    uint24 public constant FEE_1 = 500; //pool 0.05% fee // best for stable pairs
    uint24 public constant FEE_2 = 10000; // pool 1% fee // best for exotic pairs

    constructor(address _factory) {
        require(_factory != address(0), "zero address");
        factory = _factory;
    }

    function consult(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) public view override returns (uint256 quoteAmount) {
        address pool = getPool(_tokenIn, _tokenOut);

        if (pool == address(0)) {
            return 0;
        }

        (int24 timeWeightedAverageTick, ) = OracleLibrary.consult(
            pool,
            uint32(PERIOD)
        );
        quoteAmount = OracleLibrary.getQuoteAtTick(
            timeWeightedAverageTick,
            uint128(_amountIn),
            _tokenIn,
            _tokenOut
        );
    }

    function getPool(
        address _tokenIn,
        address _tokenOut
    ) public view override returns (address pool) {
        address defaultPool = IUniswapV3Factory(factory).getPool(
            _tokenIn,
            _tokenOut,
            DEFAULT_FEE
        );
        address pool1 = IUniswapV3Factory(factory).getPool(
            _tokenIn,
            _tokenOut,
            FEE_1
        );
        address pool2 = IUniswapV3Factory(factory).getPool(
            _tokenIn,
            _tokenOut,
            FEE_2
        );

        if (defaultPool != address(0)) {
            pool = defaultPool;
        } else if (pool1 != address(0)) {
            pool = pool1;
        } else if (pool2 != address(0)) {
            pool = pool2;
        } else {
            pool = address(0);
        }
    }
}
