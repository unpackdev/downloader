// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * As I recall, I know you love to show off
 * But I never thought that you would take it this far
 * What do I know?
 */
contract FlashingLights is AdminControl, ICreatorExtensionTokenURI {

    using Strings for uint256;

    address private _creator;
    uint private _tokenId;
    string public _script;
    string private _name;
    string private _description;
    string private _attributes;
    string[2] private _previews;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function mint() public adminRequired {
        require(_tokenId == 0, 'Token already minted');
        _tokenId = IERC721CreatorCore(_creator).mintExtension(msg.sender);
    }

    function setScript(string memory script) public adminRequired {
      _script = script;
    }

    function setName(string memory name) public adminRequired {
      _name = name;
    }

    function setDescription(string memory description) public adminRequired {
      _description = description;
    }

    function setAttributes(string memory attributes) public adminRequired {
      _attributes = attributes;
    }

    function setPreviews(string memory imagePreview, string memory videoPreview) public {
      require(IERC721(_creator).ownerOf(_tokenId) == msg.sender || isAdmin(msg.sender), "Only owner or admin can change.");
      _previews[0] = imagePreview;
      _previews[1] = videoPreview;
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && tokenId == _tokenId, "Invalid token");
        return string(abi.encodePacked('data:application/json;utf8,',
        '{"name":"',
        _name,
        '","created_by":"yung wknd","description":"',
        _description,
        '","image":"',
        _previews[0],
        '","image_url":"',
        _previews[0],
        '","animation":"',
        _previews[1],
        '","animation_url":"',
        _previews[1],
        '","attributes":[',
        _attributes,
        ']}'));
    }
}
