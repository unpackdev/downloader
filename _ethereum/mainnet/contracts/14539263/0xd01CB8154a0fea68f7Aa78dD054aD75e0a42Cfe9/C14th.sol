// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";

interface ILazyDelivery is IERC165 {
    function deliver(address caller, uint256 listingId, uint256 assetId, address to, uint256 payableAmount, uint256 index) external returns(uint256);
}

interface ILazyDeliveryMetadata is IERC165 {
    function assetURI(uint256 assetId) external view returns(string memory);
}

contract C14th is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {

    using Strings for uint256;

    address private _creator;
    string private _baseURI;

    address private _marketplace;
    uint private _listingId;
    uint private _discountListingId;

    // Set the minters to true, flip to false when they mint
    mapping(address => bool) _minters;
    mapping(address => bool) _freeMinters;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setMinters(address[] memory minters) public adminRequired {
        for (uint i; i < minters.length; i++) {
            _minters[minters[i]] = true;
        }
    }

    function setFreeMinters(address[] memory freeMinters) public adminRequired {
        for (uint i; i < freeMinters.length; i++) {
            _freeMinters[freeMinters[i]] = true;
        }
    }

    function setListing(uint listingId, uint discountListingId, address marketplace) public adminRequired {
        _listingId = listingId;
        _discountListingId = discountListingId;
        _marketplace = marketplace;
    }

    function deliver(address, uint256 listingId, uint256, address to, uint256, uint256) external override returns(uint256) {
        require(msg.sender == _marketplace &&
                    (listingId == _listingId || listingId == _discountListingId),
            "Invalid call data");

        if (listingId == _discountListingId) {
            require(_freeMinters[to], "Not allowed to mint for free.");
            _freeMinters[to] = false;
        }

        if (listingId == _listingId) {
            require(_minters[to], "Not allowed to mint.");
            _minters[to] = false;
        }

        IERC721CreatorCore(_creator).mintExtension(to);
        return 0;
    }

    function setBaseURI(string memory baseURI) public adminRequired {
      _baseURI = baseURI;
    }

    function assetURI(uint256 assetId) external view override returns(string memory) {
        return string(abi.encodePacked(_baseURI, assetId.toString(), ".json"));
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return this.assetURI(tokenId);
    }
}
