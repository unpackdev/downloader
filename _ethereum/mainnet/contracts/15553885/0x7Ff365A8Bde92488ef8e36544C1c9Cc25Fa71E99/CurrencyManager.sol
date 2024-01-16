// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./EnumerableSet.sol";

import "./TheCurrencyManager.sol";

//  Allow adding different currency for transaction
contract CurrencyManager is TheCurrencyManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelistedCurrencies;

    event CurrencyRemoved(address indexed currency);
    event CurrencyWhitelisted(address indexed currency);

    //
    // function addCurrency
    //  @Description: Add a currency
    //  @param address
    //  @return external
    //
    function addCurrency(address currency) external override onlyOwner {
        // Check if the currency to be added exists
        require(!_whitelistedCurrencies.contains(currency), " Already whitelisted");
        _whitelistedCurrencies.add(currency);

        emit CurrencyWhitelisted(currency);
    }

    //
    // function removeCurrency
    //  @Description: Delete a currency
    //  @param address
    //  @return external
    //
    function removeCurrency(address currency) external override onlyOwner {
        // Check if the currency to be deleted exists
        require(_whitelistedCurrencies.contains(currency), " Not whitelisted");
        _whitelistedCurrencies.remove(currency);

        emit CurrencyRemoved(currency);
    }

    //
    // function isCurrencyWhitelisted
    //  @Description: Check if the currency is whitelisted
    //  @param address
    //  @return external
    //
    function isCurrencyWhitelisted(address currency) external view override returns (bool) {
        return _whitelistedCurrencies.contains(currency);
    }

    //
    // function viewCountWhitelistedCurrencies
    //  @Description: Count number of whitelisted currencies
    //  @return external
    //
    function viewCountWhitelistedCurrencies() external view override returns (uint256) {
        return _whitelistedCurrencies.length();
    }

    //
    // function viewWhitelistedCurrencies
    //  @Description: Look through all whitelisted currencies
    //  @param uint256
    //  @param uint256
    //  @return external
    //
    function viewWhitelistedCurrencies(uint256 cursor, uint256 size)
    external
    view
    override
    returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _whitelistedCurrencies.length() - cursor) {
            length = _whitelistedCurrencies.length() - cursor;
        }

        address[] memory whitelistedCurrencies = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedCurrencies[i] = _whitelistedCurrencies.at(cursor + i);
        }

        return (whitelistedCurrencies, cursor + length);
    }
}
