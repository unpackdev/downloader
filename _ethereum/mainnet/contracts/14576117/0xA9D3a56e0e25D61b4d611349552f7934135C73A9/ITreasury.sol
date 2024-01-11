//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./console.sol";

interface ITreasury {
    /**
     * @notice primary sale (invoked by nft contract on mint)
     */
    function primarySale() external payable;

    /**
     * @notice secondary sale (invoked by ERC-2981)
     */
    receive() external payable;
}