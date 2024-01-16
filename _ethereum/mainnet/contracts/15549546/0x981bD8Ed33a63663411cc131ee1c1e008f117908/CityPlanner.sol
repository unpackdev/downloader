// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC721.sol";
import "./ERC165.sol";

//City Planner 🏙🛸🌲
contract CityPlanner is AdminControl, ICreatorExtensionTokenURI {

    address public _creator;
    uint public _tokenId;

    string[] public _imageParts;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function ownerConfigure(string memory uriPart) public {
        require(IERC721(_creator).ownerOf(_tokenId) == msg.sender, "Must own the NFT");
        _imageParts.push(uriPart);
    }

    function clear() public {
      require(IERC721(_creator).ownerOf(_tokenId) == msg.sender, "Must own the NFT");
      for (uint i; i < _imageParts.length; i++) {
        delete _imageParts[i];
      }
    }

    function mint(address creator) public adminRequired {
        require(_tokenId == 0, "Cannot mint again");
        _creator = creator;
        _tokenId = IERC721CreatorCore(_creator).mintExtension(msg.sender);
    }

    function tokenURI(address, uint256) public view override returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;utf8,',
            '{"name":"City Planner","description":"City Planner is a fully customizable City Park.",',
            '"image":"',
                _generateImage(),
            '"}'));
    }

    function _generateImage() private view returns (string memory) {
      string memory image = 'data:image/svg+xml;utf8,';
      for (uint i; i < _imageParts.length; i++) {
        image = string(abi.encodePacked(image, _imageParts[i]));
      }
        return image;
    }
}
