// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title IERC1155 Non-Fungible Token Creator basic interface
 */
interface IERC1155TokenCreator {
    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(uint256 _tokenId)
    external
    view
    returns (address payable);
}
