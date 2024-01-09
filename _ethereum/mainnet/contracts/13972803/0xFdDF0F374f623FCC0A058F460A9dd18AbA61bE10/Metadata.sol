// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

pragma experimental ABIEncoderV2;
import "./base64.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./IBalloonToken.sol";

contract Metadata is Ownable {
  using Strings for uint256;

  // utility token
  IBalloonToken public utilityToken;

  // Utility Token Fee to update Name, Bio
  uint256 public _changeNameFee = 10 * 10**18;
  uint256 public _changeBioFee = 25 * 10**18;
  uint256 TotalSupply;

  // Image Placeholder URI
  string public placeHolderURI;

  // Public Reveal Status
  bool public PublicRevealStatus = false;

  struct Meta {
    string name;
    string description;
  }

  // Mapping from tokenId to meta struct
  mapping(uint256 => Meta) metaList;

  // Mapping from tokenId to boolean to make sure name is updated.
  mapping(uint256 => bool) _isNameUpdated;

  // Mapping from tokenId to boolean to make sure bio is updated.
  mapping(uint256 => bool) _isBioUpdated;

  // Mapping from token Id to mint date
  mapping(uint256 => uint256) tokenMintDate;

  constructor(address _utilityToken, uint256 _totalSupply) {
    utilityToken = IBalloonToken(_utilityToken);
    TotalSupply = _totalSupply;
  }

  function changeName(uint256 _tokenId, string memory _name) external {
    Meta storage _meta = metaList[_tokenId];
    _meta.name = _name;
    _isNameUpdated[_tokenId] = true;
    utilityToken.burn(msg.sender, _changeNameFee);
  }

  function changeBio(uint256 _tokenId, string memory _bio) external {
    Meta storage _meta = metaList[_tokenId];
    _meta.description = _bio;
    _isBioUpdated[_tokenId] = true;
    utilityToken.burn(msg.sender, _changeBioFee);
  }

  function getTokenName(uint256 _tokenId) public view returns (string memory) {
    return metaList[_tokenId].name;
  }

  function getTokenBio(uint256 _tokenId) public view returns (string memory) {
    return metaList[_tokenId].description;
  }

  function setPlaceholderURI(string memory uri) public onlyOwner {
    placeHolderURI = uri;
  }

  function togglePublicReveal() external onlyOwner {
    PublicRevealStatus = !PublicRevealStatus;
  }

  function _getTokenMintDate(uint256 tokenId) internal view returns (uint256) {
    return tokenMintDate[tokenId];
  }

  function setChangeNameFee(uint256 _fee) external onlyOwner {
    _changeNameFee = _fee;
  }

  function setChangeBioFee(uint256 _fee) external onlyOwner {
    _changeBioFee = _fee;
  }
}
