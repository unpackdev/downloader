// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.2;

interface IMarket {
    function getFeeConfig()
    external
    view
    returns (
        uint256 secondaryFakturaFeeBasisPoints,
        uint256 secondaryCreatorFeeBasisPoints
    );
}