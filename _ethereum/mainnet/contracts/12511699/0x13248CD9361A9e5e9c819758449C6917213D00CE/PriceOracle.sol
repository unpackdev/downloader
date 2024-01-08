// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Governable.sol";
import "./IPriceOracle.sol";

contract PriceOracle is IPriceOracle, Governable {

    mapping(address => uint) public priceMap;

    event setPriceEvent(address token, uint price);

    constructor(address governorAddr) {
        __Governable__init(governorAddr);
    }

    /// @notice Return the value of the given token in ETH.
    /// @param token The ERC20 token
    function getPrice(address token) external view override returns (uint) {
        uint price = priceMap[token];
        require(price != 0, 'getPrice: price not found.');
        return price;
    }

    /// @notice Set the prices of the given tokens.
    /// @param tokens The tokens to set the prices.
    /// @param prices The prices of tokens.
    function setPrices(address[] memory tokens, uint[] memory prices) external onlyGov {
        require(tokens.length == prices.length, 'setPrices: lengths do not match');
        for (uint i = 0; i < tokens.length; i++) {
            priceMap[tokens[i]] = prices[i];
            emit setPriceEvent(tokens[i], prices[i]);
        }
    }
}
