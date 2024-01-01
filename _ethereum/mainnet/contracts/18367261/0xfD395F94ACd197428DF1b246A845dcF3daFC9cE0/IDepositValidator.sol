// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDepositValidator {
    /// @notice Check if the given nft is valid one for being used in nft vault
    /// @dev nftAddress is only used at the moment, other args may be used later
    /// @dev Only ERC721 standard is being supported at the moment
    function isValid(
        address /* remitter_ */, // may be used later
        address nftAddress_,
        uint256 /* nftTokenId_ */ // may be used later
    ) external view returns (bool);
}
