// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IExchangeRates {
    function addCurrencyKey(bytes32 currencyKey_, address aggregator_) external;

    function updateCurrencyKey(bytes32 currencyKey_, address aggregator_) external;

    function deleteCurrencyKey(bytes32 currencyKey) external;

    function rateForCurrency(bytes32 currencyKey) external view returns (uint32, uint);

    function rateForCurrencyByIdx(uint32 idx) external view returns (uint);

    function currencyKeyExist(bytes32 currencyKey) external view returns (bool);
}
