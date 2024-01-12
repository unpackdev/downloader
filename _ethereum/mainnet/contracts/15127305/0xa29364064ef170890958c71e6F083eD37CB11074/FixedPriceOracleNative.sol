// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./Governable.sol";
import "./AggregatorInterface.sol";
import "./SafeCast.sol";

/**
 * @title FixedPriceOracle to store fix price for the token in USD rate and return in native token.
 * The USD price is in 8 decimals and converted in native token
 */
contract FixedPriceOracleNative is AggregatorInterface, Governable {
    using SafeCast for uint256;

    // Token for which the price is stored
    address public token;
    // price of the token in USD in 8 decimals meaning `1 USD = 10^8`
    uint256 public price;

    uint256 public lastUpdated;

    event PriceUpdated(address indexed _token, uint256 _newPrice);

    constructor(
        address _gemGlobalConfig,
        address _token,
        uint256 _initPriceInUSD8
    ) {
        _init(_gemGlobalConfig);
        token = _token;
        price = _initPriceInUSD8;
        emit PriceUpdated(token, price);
    }

    /**
     * @dev Governance can update the price of the token
     * @param _token token address
     * @param _newPriceInUSD8 new price of the token in USD with 8 decimal places
     */
    function updatePrice(address _token, uint256 _newPriceInUSD8) external onlyGov {
        // for safety checking that the token address is correct
        require(_token == token, "FixedPriceOracle: token mismatch");
        price = _newPriceInUSD8;
        lastUpdated = block.timestamp;
        emit PriceUpdated(_token, _newPriceInUSD8);
    }

    /**
     * @dev Convert the USD price with respect to native token price
     * @return priceInNative price of the token in native currency
     */
    function latestAnswer() external view override returns (int256 priceInNative) {
        int256 nativeTokenPriceInUSD8 = gemGlobalConfig.getNativeTokenPriceInUSD8();
        int256 tokenPriceInUSD8 = price.toInt256();
        priceInNative = (1e18 * tokenPriceInUSD8) / nativeTokenPriceInUSD8;
    }

    function latestTimestamp() external view override returns (uint256) {
        // just returning current time as this oracle should not expire
        return block.timestamp;
    }

    /* solhint-disable no-empty-blocks */

    function latestRound() external view override returns (uint256) {
        // NO BODY
    }

    function getAnswer(uint256 roundId) external view override returns (int256) {
        // NO BODY
    }

    function getTimestamp(uint256 roundId) external view override returns (uint256) {
        // NO BODY
    }

    /* solhint-enable no-empty-blocks */
}
