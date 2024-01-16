// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceContract {
    struct Price {
        uint256 value;
        uint256 decimals;
    }

    event GetPrice(bytes32 _id, string _query, uint256 _timestamp);
    event ReceivePrice(bytes32 _id, uint256 _value, uint256 decimals);

    function updatePrice(
        uint256 _time,
        address _tokens,
        uint256 _priceDecimals
    ) external returns (bytes32);

    function checkFulfill(bytes32 _requestId) external view returns (bool);

    function getPrice(bytes32 _id)
        external
        view
        returns (uint256 value, uint256 decimals);
}
