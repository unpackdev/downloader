// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICollectionProfitSplit {
    function getProfitSplit(address token_address_)
        external
        view
        returns (
            address[] memory profit_split_addresses,
            uint256[] memory profit_split_values,
            uint256 total
        );
}
