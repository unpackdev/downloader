/*
    Copyright 2020 Dynamic Dollar Devs, based on the works of the Empty Set Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";
import "./Require.sol";
import "./Decimal.sol";
import "./IOracle.sol";
import "./IUSDC.sol";
import "./Constants.sol";

contract CDSDOracle is IOracle {
    using Decimal for Decimal.D256;

    bytes32 private constant FILE = "Oracle";
    address private constant SUSHISWAP_FACTORY = address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac); // Sushi Factory Address

    bool internal _initialized;
    IUniswapV2Pair internal _pair;
    uint256 internal _index;
    uint256 internal _cumulative;
    uint256 internal _reserve;
    uint32 internal _timestamp;

    function setup() public onlyDao {
        _pair = IUniswapV2Pair(
            IUniswapV2Factory(SUSHISWAP_FACTORY).getPair(Constants.getContractionDollarAddress(), usdc())
        );
        (address token0, address token1) = (_pair.token0(), _pair.token1());
        _index = Constants.getContractionDollarAddress() == token0 ? 0 : 1;
        Require.that(_index == 0 || Constants.getContractionDollarAddress() == token1, FILE, "CDSD not found");
    }

    /**
     * Trades/Liquidity: (1) Initializes reserve and blockTimestampLast (can calculate a price)
     *                   (2) Has non-zero cumulative prices
     *
     * Steps: (1) Captures a reference blockTimestampLast
     *        (2) First reported value
     */
    function capture() public onlyDao returns (Decimal.D256 memory, bool) {
        if (_initialized) {
            return updateOracle();
        } else {
            initializeOracle();
            return (Decimal.one(), false);
        }
    }

    function initializeOracle() private {
        IUniswapV2Pair pair = _pair;
        uint256 priceCumulative = _index == 0 ? pair.price0CumulativeLast() : pair.price1CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();

        if (reserve0 != 0 && reserve1 != 0 && blockTimestampLast != 0) {
            _cumulative = priceCumulative;
            _timestamp = blockTimestampLast;
            _reserve = _index == 0 ? reserve1 : reserve0;

            _initialized = true;
        }
    }

    function updateOracle() private returns (Decimal.D256 memory, bool) {
        Decimal.D256 memory price = updatePrice();
        uint256 lastReserve = updateReserve();
        bool isBlacklisted = IUSDC(usdc()).isBlacklisted(address(_pair));

        bool valid = true;
        if (lastReserve < Constants.getContractionOracleReserveMinimum()) {
            valid = false;
        }
        if (_reserve < Constants.getContractionOracleReserveMinimum()) {
            valid = false;
        }
        if (isBlacklisted) {
            valid = false;
        }

        return (price, valid);
    }

    function updatePrice() private returns (Decimal.D256 memory) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
        uint32 timeElapsed = blockTimestamp - _timestamp; // overflow is desired
        uint256 priceCumulative = _index == 0 ? price0Cumulative : price1Cumulative;
        Decimal.D256 memory price = Decimal.ratio((priceCumulative - _cumulative) / timeElapsed, 2**112);

        _timestamp = blockTimestamp;
        _cumulative = priceCumulative;

        return price.mul(1e12);
    }

    /**
     * @dev Get current TWAP from oracle. For convenience sake
     */
    function getCurrentTwapPrice() public view returns (uint256 value) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
        uint32 timeElapsed = blockTimestamp - _timestamp; // overflow is desired

        uint256 priceCumulative = _index == 0 ? price0Cumulative : price1Cumulative;

        Decimal.D256 memory price = Decimal.ratio((priceCumulative - _cumulative) / timeElapsed, 2**112);

        return price.mul(1e12).value;
    }

    function updateReserve() private returns (uint256) {
        uint256 lastReserve = _reserve;
        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        _reserve = _index == 0 ? reserve1 : reserve0;

        return lastReserve;
    }

    function usdc() internal view returns (address) {
        return Constants.getUsdcAddress();
    }

    function pair() external view returns (address) {
        return address(_pair);
    }

    function reserve() external view returns (uint256) {
        return _reserve;
    }

    modifier onlyDao() {
        Require.that(msg.sender == Constants.getDaoAddress(), FILE, "Not DAO");

        _;
    }
}
