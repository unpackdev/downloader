// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

interface ICToken {

    function exchangeRateStored()
        external
        view
        returns (uint);

    function underlying()
        external
        view
        returns (address);

    function decimals()
        external
        view
        returns (uint8);

}
