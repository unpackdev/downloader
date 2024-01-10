// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: yungwknd
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./ILazyDelivery.sol";
import "./ILazyDeliveryMetadata.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";

interface IAshCC is IERC165 {
    function addPoints(uint tokenId, uint numPoints) external;
}

contract Buffon is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {

    using Strings for uint256;
    using Strings for uint16;

    address private _creator;
    address private _marketplace;
    uint private _listingId;
    string private _baseURI;
    string private _image;
    mapping(uint => uint16) hashes;
    mapping(uint => bool) isRare;

    IAshCC _ashCC;
    address _ashCCCore;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setListing(uint listingId, address marketplace) public adminRequired {
        _listingId = listingId;
        _marketplace = marketplace;
    }

    function preMint(address[] memory receivers) public adminRequired {
        for (uint i; i < receivers.length; i++) {
            uint tokenId = IERC721CreatorCore(_creator).mintExtension(receivers[i]);
            hashes[tokenId] = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, receivers[i]))));
        }
    }

    function deliver(address, uint256 listingId, uint256 assetId, address to, uint256, uint256 index) external override returns(uint256) {
        require(msg.sender == _marketplace &&
                    listingId == _listingId &&
                    assetId == 1 && index == 0,
            "Invalid call data");
            
        uint tokenId = IERC721CreatorCore(_creator).mintExtension(to);
        hashes[tokenId] = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, msg.sender))));

        if (tokenId == 314) {
            isRare[tokenId] = true;
        } else if (hashes[tokenId] < 206) { // about 0.00314 of uint16 token space
            isRare[tokenId] = true;
        }

        if (IERC721(_ashCCCore).balanceOf(to) > 0) {
            for (uint i = 1; i <= 24; i++) {
                if (IERC721(_ashCCCore).ownerOf(i) == to) {
                    _ashCC.addPoints(i, 3);
                    return 0;
                }
            }
        }
    }

    function setBaseURI(string memory baseURI) public adminRequired {
      _baseURI = baseURI;
    }

    function setImage(string memory image) public adminRequired {
      _image = image;
    }

    function setRewardsCard(address ashCC, address ashCCCore) public adminRequired {
      _ashCC = IAshCC(ashCC);
      _ashCCCore = ashCCCore;
    }

    function _boolToString(bool value) private pure returns (string memory) {
        if (value) {
            return "True";
        } else {
            return "False";
        }
    }

    function getAnimationURL(uint assetId) private view returns (string memory) {
        return string(abi.encodePacked(_baseURI, assetId.toString(), ":", hashes[assetId].toString(), "&rare=", _boolToString(isRare[assetId])));
    }

    function getName(uint assetId) private pure returns (string memory) {
        return string(abi.encodePacked("Buffon's Needle #", assetId.toString()));
    }

    function assetURI(uint256 assetId) external view override returns(string memory) {
        return string(abi.encodePacked('data:application/json;utf8,',
        '{"name":"',
        getName(assetId),
        '","created_by":"yung wknd","description":"Happy Pi Day!","animation":"',
        getAnimationURL(assetId),
        '","animation_url":"',
        getAnimationURL(assetId),
        '","image":"',
        _image,
        '","image_url":"',
        _image,
        '"}'));
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return this.assetURI(tokenId);
    }
}
