// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibPriceConsumerStorage.sol";
import "./IUniswapV3Router.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapOracleV3.sol";

library LibPriceConsumer {
    function getPair(
        address _token0,
        address _token1
    ) internal view returns (address pair) {
        LibPriceConsumerStorage.PriceConsumerStorage
            storage s = LibPriceConsumerStorage.priceConsumerStorage();

        pair = s.oracle.getPool(_token0, _token1);
    }
}
