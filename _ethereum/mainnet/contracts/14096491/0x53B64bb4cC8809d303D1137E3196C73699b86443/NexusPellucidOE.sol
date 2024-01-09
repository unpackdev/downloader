// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * Nexus > Pellucid - Open Edition by xsullo
 */
contract NexusPellucidOE is AdminControl, ICreatorExtensionTokenURI, ReentrancyGuard {

  using Strings for uint256;
  
  bool private _active;
  uint256 private _total;
  uint256 private _totalMinted;
  address private _creator;
  address private _nifty_omnibus_wallet;
  string[] private _uriParts;
  mapping(uint256 => uint256) private _tokenEdition;
  string constant private _EDITION_TAG = '<EDITION>';
  string constant private _TOTAL_TAG = '<TOTAL>';

  constructor(address creator) {
    _active = false;
    _creator = creator;
    _uriParts.push('data:application/json;utf8,{"name":"Pellucid #');
    _uriParts.push('<EDITION>');
    _uriParts.push('/');
    _uriParts.push('<TOTAL>');
    _uriParts.push('", "created_by":"xsullo", ');
    _uriParts.push('"description":"This open edition unlocks the next collectors drop here on Nifty.\\nVisuals & Audio by xsullo.\\n2022.  Minted with Manifold.", ');
    _uriParts.push('"image":"https://arweave.net/Rv14TuqjNn8U0W7eX3s_j5DdH6OALTOkxMZECxVx4bA","image_url":"https://arweave.net/Rv14TuqjNn8U0W7eX3s_j5DdH6OALTOkxMZECxVx4bA","image_details":{"sha256":"12e99eba9513e99fad7d464b19951d0a8b124f130907cdf03ce629c42e6546a7","bytes":6136532,"width":2120,"height":2400,"format":"JPEG"},');
    _uriParts.push('"animation":"https://arweave.net/Jr6EUzeKpPlwr6LQeT89E0LRV_4wtxzc9QWPIbVXPX0","animation_url":"https://arweave.net/Jr6EUzeKpPlwr6LQeT89E0LRV_4wtxzc9QWPIbVXPX0","animation_details":{"sha256":"0c5cec4676132dfce1cd17de334175598b0ea3befbe929e348325111acc87d62","bytes":103275550,"width":1808,"height":2048,"duration":30,"format":"MP4","codecs":["H.264","AAC"]},');
    _uriParts.push('"attributes":[{"trait_type":"Artist","value":"xsullo"},{"trait_type":"Auctioneer","value":"Nifty Gateway"},{"trait_type":"Collection","value":"Nexus"},{"trait_type":"Year","value":"2022"},{"display_type":"number","trait_type":"Edition","value":');
    _uriParts.push('<EDITION>');
    _uriParts.push(',"max_value":');
    _uriParts.push('<TOTAL>');
    _uriParts.push('}]}');
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
    return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
  }

  function activate(uint256 total, address nifty_omnibus_wallet) external adminRequired {
    require(!_active, "Already activated!");
    _active = true;
    _total = total;
    _totalMinted = 0;
    _nifty_omnibus_wallet = nifty_omnibus_wallet;
  }

  function _mintCount(uint256 niftyType) external view returns (uint256) {
      require(niftyType == 1, "Only supports niftyType is 1");
      return _totalMinted;
  }

  function mintNifty(uint256 niftyType, uint256 count) external adminRequired nonReentrant {
    require(_active, "Not activated.");
    require(_totalMinted+count <= _total, "Too many requested.");
    require(niftyType == 1, "Only supports niftyType is 1");
    for (uint256 i = 0; i < count; i++) {
      _tokenEdition[IERC721CreatorCore(_creator).mintExtension(_nifty_omnibus_wallet)] = _totalMinted + i + 1;
    }
    _totalMinted += count;
  }

  function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
    require(creator == _creator && _tokenEdition[tokenId] != 0, "Invalid token");
    return _generateURI(tokenId);
  }

  function _generateURI(uint256 tokenId) private view returns(string memory) {
    bytes memory byteString;
    for (uint i = 0; i < _uriParts.length; i++) {
      if (_checkTag(_uriParts[i], _EDITION_TAG)) {
        byteString = abi.encodePacked(byteString, _tokenEdition[tokenId].toString());
      } else if (_checkTag(_uriParts[i], _TOTAL_TAG)) {
        byteString = abi.encodePacked(byteString, _total.toString());
      } else {
        byteString = abi.encodePacked(byteString, _uriParts[i]);
      }
    }
    return string(byteString);
  }

  function _checkTag(string storage a, string memory b) private pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  /**
    * @dev update the URI data
    */
  function updateURIParts(string[] memory uriParts) public adminRequired {
    _uriParts = uriParts;
  }
}
