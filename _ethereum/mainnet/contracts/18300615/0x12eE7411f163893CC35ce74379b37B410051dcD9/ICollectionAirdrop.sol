// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICollectionAirdrop {
    function getList(address token_address_)
        external
        returns (address[] memory);

    function isMember(address token_address_, address eth_address)
        external
        returns (bool);

    function getOptions(address token_address_) external returns (uint256 free_mint);
}
