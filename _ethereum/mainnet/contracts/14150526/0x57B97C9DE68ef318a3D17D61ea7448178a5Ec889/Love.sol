// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./IERC721CreatorCore.sol";
import "./ILazyDelivery.sol";
import "./ILazyDeliveryMetadata.sol";

import "./Strings.sol";
import "./ERC165.sol";
import "./EnumerableSet.sol";

/**
 * They ask for equal dignity in the eyes of the law.
 * The Constitution grants them that right.
 * - Justice Kennedy, Supreme Court
 */
contract Love is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {

    using Strings for uint256;
    using Strings for uint16;

    address private _creator;
    address private _marketplace;
    string private _image;
    address private _receiver;

    uint _listingId;

    mapping(address => bool) minters;

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

    function deliver(address, uint256 listingId, uint256 assetId, address, uint256, uint256 index) external override returns(uint256) {
        require(msg.sender == _marketplace &&
                    listingId == _listingId &&
                    assetId == 1 && index == 0,
            "Invalid call data");

        IERC721CreatorCore(_creator).mintExtension(_receiver);
        return 0;
    }

    function setReceiver(address receiver) public adminRequired {
      _receiver = receiver;
    }

    function setImage(string memory image) public adminRequired {
        _image = image;
    }

    function assetURI(uint256) external view override returns(string memory) {
        return string(abi.encodePacked('data:application/json;utf8,',
        '{"name":"Love","created_by":"The People","description":"They ask for equal dignity in the eyes of the law. The Constitution grants them that right.",',
        '"image":"',
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
