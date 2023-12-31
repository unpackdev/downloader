// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @notice transferFrom() is used by Issue 123 contract to transfer tokens to CETokenMinter contract
 * and then call burn(). mint() is called by CETokenMinter contract to mint CE Token.
 */
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function burn(uint256 _tokenId) external;

    function mint(
        address _account,
        uint256 _amountToMint,
        uint256 _freeClaimAmount,
        uint256[][] calldata _tokenIdsBurned
    ) external;
}
