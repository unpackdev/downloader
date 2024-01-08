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
 * Aku - Chapter 3
 * A Nifty Gateway drop
 */
contract AkuChapter3 is AdminControl, ICreatorExtensionTokenURI, ReentrancyGuard {

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
    _uriParts.push('data:application/json;utf8,{"name":"Aku Chapter III: Escape #');
    _uriParts.push('<EDITION>');
    _uriParts.push('/');
    _uriParts.push('<TOTAL>');
    _uriParts.push('", "created_by":"Micah Johnson", ');
    _uriParts.push('"description":"In a time where much of our lives are spent in the digital world, the anxiety and pressure to measure up to others can have a major impact on our well-being. At one point or another, we all ask ourselves, \\"Am I doing enough?\\". Aku must navigate through the same challenges we all face. Thankfully, Aku has found an escape.", ');
    _uriParts.push('"image":"https://arweave.net/M9LnxCggMO_pAf-5mpbD0hPFSnznY3h7uBOmPonddG0","image_url":"https://arweave.net/M9LnxCggMO_pAf-5mpbD0hPFSnznY3h7uBOmPonddG0","image_details":{"sha256":"95fa7508265a737379832ecba28ec22e6e4b212c6ed7969733945938094e36ad","bytes":1248981,"width":1920,"height":1080,"format":"PNG"},');
    _uriParts.push('"animation":"https://arweave.net/UR1YMq6cFeMkWmnD81NDuXog2u3tY8q5jYelBAKvr4c","animation_url":"https://arweave.net/UR1YMq6cFeMkWmnD81NDuXog2u3tY8q5jYelBAKvr4c","animation_details":{"sha256":"d9a3896d81537d1fc577be81b4b985bf6cc825d8c5f4709078f64965f4ee9230","bytes":242259353,"width":1920,"height":1080,"duration":82,"format":"MP4","codecs":["H.264","AAC"]},');
    _uriParts.push('"attributes":[{"trait_type":"Artist","value":"Micah Johnson"},{"trait_type":"Collection","value":"Aku"},{"trait_type":"Chapter","value":"III"},{"display_type":"number","trait_type":"Edition","value":');
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
