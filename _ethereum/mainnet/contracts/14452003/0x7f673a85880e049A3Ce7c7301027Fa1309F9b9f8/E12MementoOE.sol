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

contract E12MementoOE is AdminControl, ICreatorExtensionTokenURI, ReentrancyGuard {

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
    _uriParts.push('data:application/json;utf8,{"name":"E12 Memento #');
    _uriParts.push('<EDITION>');
    _uriParts.push('/');
    _uriParts.push('<TOTAL>');
    _uriParts.push('", "created_by":"Sov x Undeadlu", ');
    _uriParts.push('"external_url":"https://niftygateway.com/collections/zuxori", ');
    _uriParts.push('"description":"Lucrezia studies perfumery, seeking to remember her father. Lauren rescues Zu from the Capulets. Tai unlocks his past lives and tries to save Ori. Zu is late and her performance takes a tragic turn.\\n\\nView Episode 12: https://arweave.net/H3mzTuAIRxUMsVO5ioppNgebrSAYhXVux0Z0cPeGZL8\\n\\nView on-chain text: https://arweave.net/ukHR7UGu7iGyj4eFWkblg0lcxDB7f3-EM-Lx8MySdHo", ');
    _uriParts.push('"ZU X ORI Full Story":"https://arweave.net/4m5U6TYjcDj6kt19-hCFneCOHRpHZlfthh_lpeWxzKU", ');
    _uriParts.push('"image":"https://arweave.net/Cr69zdtfOZftQImXfbwwLbfx2foHpN8RYAxGHHT18Fs","image_url":"https://arweave.net/Cr69zdtfOZftQImXfbwwLbfx2foHpN8RYAxGHHT18Fs","image_details":{"sha256":"f7e9d3d335041e776b48226cfca67968ded8d79e6087d550bef91043c74112c1","bytes":4575350,"width":2000,"height":2048,"format":"PNG"}, ');
    _uriParts.push('"attributes":[{"trait_type":"Artist","value":"Sov x Undeadlu"},{"trait_type":"Auctioneer","value":"Nifty Gateway"},{"trait_type":"Episode","value":"E12"},{"display_type":"number","trait_type":"Edition","value":');
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