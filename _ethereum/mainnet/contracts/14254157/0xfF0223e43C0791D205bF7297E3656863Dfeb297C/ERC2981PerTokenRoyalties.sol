// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";

import "./ERC2981Base.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC2981Base {
    
    RoyaltyInfo _royaltyInfo;
    

    function _setTokenRoyalty(
        address recipient,
        uint256 value
    ) internal {
        require(value <= 200000, 'ERC2981Royalties: Too high');
        _royaltyInfo = RoyaltyInfo(recipient, value);
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyInfo.recipient, _royaltyInfo.royalAmount * value / 1e4);
    }
}