// SPDX-License-Identifier: MIT
// https://github.com/dievardump/EIP2981-implementation/blob/main/contracts/ERC2981PerTokenRoyalties.sol
pragma solidity ^0.8.0;

import "ERC165.sol";

import "ERC2981Base.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC2981Base {

    RoyaltyInfo _royaltyInfo;

    /// @dev Sets token royalties
    /// @param royaltyInfo.recipient recipient of the royalties
    /// @param royaltyInfo.royalAmount percentage (using 4 decimals - 1000000 = 100, 0 = 0)
    function _setTokenRoyalty(RoyaltyInfo memory royaltyInfo) internal {
        //PercentBase = 1e6, so 1e6 : 100% Percent
        require(royaltyInfo.royalAmount <= 1e6, 'ERC2981Royalties: Too high');
        _royaltyInfo = royaltyInfo;
//        _royaltyInfo = RoyaltyInfo(recipient, value);
    }

    function royaltyInfo(uint256 tokenId, uint256 value) external view override
    returns (address receiver, uint256 royaltyAmount) {
        //PercentBase = 1e6
        return (_royaltyInfo.recipient, _royaltyInfo.royalAmount * value / 1e6);
    }
}