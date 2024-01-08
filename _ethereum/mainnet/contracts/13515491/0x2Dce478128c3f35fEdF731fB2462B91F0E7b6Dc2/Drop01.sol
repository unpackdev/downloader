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
 * DAT.XYZ - Drop 01
 * A Nifty Gateway drop
 */
contract DATDOTXYZ01 is AdminControl, ICreatorExtensionTokenURI, ReentrancyGuard {

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
    _uriParts.push('data:application/json;utf8,{"name":"KEITH HARING RESURRECTED! #');
    _uriParts.push('<EDITION>');
    _uriParts.push('/');
    _uriParts.push('<TOTAL>');
    _uriParts.push('", "created_by":"DAT.XYZ", ');
    _uriParts.push('"description":"Several years ago, the artists DAT.XYZ began the unauthorised collection of microbiological samples by illicitly swabbing* the surface of world-famous artworks ... and then legging it.\\n\\nBack in their laboratory they grow new artworks directly from these swabs - a living collection of pirated masterpieces.\\n\\n\'This is a real, new kind of generative art born directly from nature herself. By stealing microbiological data from the surface of major artworks and bringing it to life - we resurrect dead painters and mutate living artists - a physical bridge is created between their original artworks and these NFTs.\'\\n\\nThe growth of each artwork is captured on industrial, high-resolution cameras and processed into a collection of evolving video loops. These beautiful Attenborough-esque, detailed time-lapse films, bearing their original artists\' name, become the NFTs (New Fungus Tokens! ;)\\n\\n*Please note - no works of art were harmed in this process.", ');
    _uriParts.push('"image":"https://arweave.net/JT8iUgsMbFrW1y0MX_2IfCq3PfdrRe7A9F1WOUQvV8A","image_url":"https://arweave.net/JT8iUgsMbFrW1y0MX_2IfCq3PfdrRe7A9F1WOUQvV8A","image_details":{"sha256":"c5dafe2d305d56b58574e3b2a5d31b2d7373c2d239b180319050e7e059681f5d","bytes":7951996,"width":2160,"height":2700,"format":"JPEG"},');
    _uriParts.push('"animation":"https://arweave.net/vOXHg0niCMWCLbP8yCLqb-4uYVorv2pL7jFZ1000D5A","animation_url":"https://arweave.net/vOXHg0niCMWCLbP8yCLqb-4uYVorv2pL7jFZ1000D5A","animation_details":{"sha256":"dc17c8c7620c712fbec18829bc17cdd6ad3f56007e52a3ef3a3ece92afd2587b","bytes":100755685,"width":2100,"height":2624,"duration":9,"format":"MP4","codecs":["H.264"]},');
    _uriParts.push('"attributes":[{"trait_type":"Artist","value":"DAT.XYZ"},{"trait_type":"Collection","value":"Drop01"},{"trait_type":"Sample","value":"Keith Haring - Untitled (1983)"},{"display_type":"number","trait_type":"Edition","value":');
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
