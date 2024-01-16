// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IPriceContract {
    struct Price {
        uint256 value;
        uint256 decimals;
    }

    event GetPrice(
        bytes32 _id,
        string _symbol,
        uint256 _timestamp,
        uint256 _decimal
    );
    event ReceivePrice(bytes32 _id, uint256 _value, uint256 decimals);

    function updatePrice(
        uint256 _time,
        address _tokens,
        uint256 _priceDecimals
    ) external returns (bytes32);

    function getPrice(bytes32 _id)
        external
        view
        returns (uint256 value, uint256 decimals);
}
