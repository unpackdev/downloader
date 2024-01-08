// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981Candidate {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value) external returns (address _receiver, uint256 _royaltyAmount);
}