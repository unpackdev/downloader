// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 */
interface INifterTokenCreatorRegistry {
    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(uint256 _tokenId)
    external
    view
    returns (address payable);

    /**
     * @dev Sets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @param _creator address of the creator for the token
     */
    function setTokenCreator(
        uint256 _tokenId,
        address payable _creator
    ) external;
}
