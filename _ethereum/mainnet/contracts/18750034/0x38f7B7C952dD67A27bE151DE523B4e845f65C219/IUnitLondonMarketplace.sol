// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Unit London.

pragma solidity ^0.8.0;

interface IUnitLondonMarketplace {
    /**
     * @notice return 3rd party address of Unit London Marketplace
     */
    function trdparty() external view returns (address);
}