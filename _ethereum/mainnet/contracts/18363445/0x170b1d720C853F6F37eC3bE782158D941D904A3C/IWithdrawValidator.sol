// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWithdrawValidator {
    /// @notice Check if the owner is able to withdraw tokens from nft vault
    /// @dev It just checks if the owner holds given `tokenId` of the `nftAddress`
    /// @dev Only ERC721 standard is being supported at the moment
    function isValid(
        address owner_,
        address nftAddress_,
        uint256 tokenId_
    ) external view returns (bool);
}
