// SPDX-License-Identifier: MIT
// Creator: Starpad x CIMED

pragma solidity ^0.8.4;

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC165.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";


//  ____  __    _  _  ___ 
// (  __)(  )  ( \/ )/ __)
//  ) _) / (_/\ )  /( (__ 
// (__)  \____/(__/  \___)


/**
 * @dev Extension of ERC721A with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981 in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 */
contract FLYC is  Ownable, ERC2981, ERC721A, ReentrancyGuard {
  uint256 public constant MAX_SUPPY = 119;
  string private baseURI;
  bool private _initialized; // false by default

  constructor(
    string memory baseURI_
  ) ERC721A("Fly Now Space Club", "FLYC") {
    baseURI = baseURI_;
    _setDefaultRoyalty(0xfD00B7654A1ce15b183b4C9B7866055281475980, 2000);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseUri(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  /**
    * @dev Mint tokens to external address
    */
  function mintTo(address _receiver, uint256 _quantity) external onlyOwner {
      require(_quantity > 0, "zero_amount");
      require(totalSupply() + _quantity <= MAX_SUPPY, "FLYC: Max supply exceeded");

      _safeMint(_receiver, _quantity);
  }

  /**
    * @dev Royalties
    */
  function setTokenRoyalty(
      uint256 tokenId,
      address receiver,
      uint96 feeNumerator
  ) external onlyOwner {
      _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator)
      external
      onlyOwner
  {
      _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
      _deleteDefaultRoyalty();
  }

  function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
      _resetTokenRoyalty(tokenId);
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721A, ERC2981)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }
}