// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165.sol";


/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _value - the sale price of the NFT asset specified by _tokenId
  /// @return _receiver - address of who should be sent the royalty payment
  /// @return _royaltyAmount - the royalty payment amount for value sale price
  function royaltyInfo(uint256 _tokenId, uint256 _value)
    external
    view
    returns (address _receiver, uint256 _royaltyAmount);
}


// File contracts/ERC2981/ERC2981Base.sol

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
  struct RoyaltyInfo {
    address recipient;
    uint256 amount;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceId);
  }
}


// File contracts/ERC2981/ERC2981ContractWideRoyalties.sol


/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC2981Base {
    RoyaltyInfo private _royalties;

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value between 0 and 1000000000000000000 percentage
    ///   (using 18 decimals: 1000000000000000000 = 100%, 0 = 0%)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 1000000000000000000, "ERC2981Royalties: Too high");
        _royalties = RoyaltyInfo(recipient, uint256(value));
    }

    function royaltyInfo(uint256 tokenID, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 1000000000000000000;
    }
}