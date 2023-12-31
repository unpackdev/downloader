// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICollectionWhiteList {
    function getOptions(address token_address_)
        external
        returns (
            uint256 whitelist_start_time,
            uint256 whitelist_amount,
            uint256 whitelist_price,
            bool is_whitelist_custody
        );

    function isMember(address token_address_, address eth_address)
        external
        returns (bool);

    function getList(address token_address_)
        external
        returns (address[] memory whitelist);
}
