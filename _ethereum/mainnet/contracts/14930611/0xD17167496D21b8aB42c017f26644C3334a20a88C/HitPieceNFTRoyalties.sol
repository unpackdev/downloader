// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./HPApprovedMarketplace.sol";
import "./IHPMarketplaceMint.sol";

import "./console.sol";

contract HitPieceNFTRoyalties is  ERC721URIStorage, ERC2981, Ownable, HPApprovedMarketplace, IHPMarketplaceMint {
  address public trustedForwarder; // relier contract address
  address private mintAdmin;

  mapping(string => uint256) private _trackIdToTokenId;
  mapping(uint256 => string) private _tokenIdToTrackId;
  Counters.Counter private tokenCount;

  event Minted(uint256 indexed tokenId, string trackId);

  constructor(address _mintAdmin, address royaltyAddress, uint96 feeNumerator, string memory tokenName, string memory token) ERC721(tokenName, token) ERC2981() {
    _setDefaultRoyalty(royaltyAddress, feeNumerator);
    mintAdmin = _mintAdmin;
  }

  function _mintTo(
    address to,
    address creatorRoyaltyAddress,
    uint96 feeNumerator,
    string memory uri,
    string memory trackId
  ) private returns (uint256) {
    require(
      _trackIdToTokenId[trackId] == 0 || _exists(0) == false,
      "Track already minted!"
    );
    uint256 newItemId = Counters.current(tokenCount);
    _mint(to, newItemId);
    _setTokenURI(newItemId, uri);
    _trackIdToTokenId[trackId] = newItemId;
    _tokenIdToTrackId[newItemId] = trackId;
    _setTokenRoyalty(newItemId, creatorRoyaltyAddress, feeNumerator);
    Counters.increment(tokenCount);

    emit Minted(newItemId, trackId);
    return newItemId;
  }

  function adminMint(
    address to,
    address creatorRoyaltyAddress,
    uint96 feeNumerator,
    string memory uri,
    string memory trackId
  ) public {
    require(mintAdmin == msg.sender, "Admin rights required");
    _mintTo(to, creatorRoyaltyAddress, feeNumerator, uri, trackId);
  }

  function marketplaceMint(
    address to,
    address creatorRoyaltyAddress,
    uint96 feeNumerator,
    string memory uri,
    string memory trackId
  ) external override(IHPMarketplaceMint) returns(uint256) {
    require(_approvedMarketplaces[msg.sender], "Only approved Marketplaces can call this function");
    uint256 newTokenId = _mintTo(to, creatorRoyaltyAddress, feeNumerator, uri, trackId);
    return newTokenId;
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(ERC721) {
    super.approve(operator, tokenId);
  }

  function getTokenIdFromTrackId(string memory trackId)
    public
    view
    returns (uint256)
  {
    return _trackIdToTokenId[trackId];
  }

  function _isTokenOwner(address requester, uint256 tokenId)
    private
    view
    returns (bool)
  {
    if (ownerOf(tokenId) == requester) {
      return true;
    }
    return false;
  }

  // ERC2981 overrides
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setMintAdmin(address newAdmin) public onlyOwner {
    mintAdmin = newAdmin;
  }

  function isApprovedForAll(address owner, address operator) override(ERC721) public view returns (bool) {
    if (_approvedMarketplaces[operator]) {
        return true;
    }
    return ERC721.isApprovedForAll(owner, operator);
  }
}