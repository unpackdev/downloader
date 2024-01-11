// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";

import "./EIP2981.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract EIP2981PerTokenRoyalties is IERC2981  {
    mapping(uint256 => RoyaltyInfo) internal _royalties;

    /// @dev Sets token royalties
    /// @param tokenId the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    function _setTokenRoyalty(
        uint256 tokenId,
        address recipient
    ) internal {
        _royalties[tokenId] = RoyaltyInfo(recipient, uint24(750));
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties[tokenId];
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
}