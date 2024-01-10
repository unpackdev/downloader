// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist holonick
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC1155CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC1155.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";


interface ILazyDelivery is IERC165 {
    function deliver(address caller, uint256 listingId, uint256 assetId, address to, uint256 payableAmount, uint256 index) external returns(uint256);
}

interface ILazyDeliveryMetadata is IERC165 {
    function assetURI(uint256 assetId) external view returns(string memory);
}

contract Holonick is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {

    using Strings for uint256;
    using Strings for uint16;

    address private _creator;
    address private _marketplace;
    mapping(uint => bool) private _listingIds;
    string private _tokenURI;

    address private _discountMarketplace;
    address private _aeternumAddress;
    address private _secondStateAddress;
    uint private _secondStateId1;
    uint private _secondStateId2;
    uint private _aeternumId;
    mapping(uint => bool) _discountListingIds;
    uint private _whichToken;

    address private _ashCCCore;
    mapping(uint => bool) _batchListingIds;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setListings(uint[] memory listingIds, address marketplace) public adminRequired {
        for (uint i; i < listingIds.length; i++) {
            _listingIds[listingIds[i]] = true;
        }
        _marketplace = marketplace;
    }

    function setDiscountListings(uint[] memory listingIds, address marketplace) public adminRequired {
        for (uint i; i < listingIds.length; i++) {
            _discountListingIds[listingIds[i]] = true;
        }
        _discountMarketplace = marketplace;
    }

    function setTokenID(uint whichToken) public adminRequired {
        _whichToken = whichToken;
    }

    function setAshCollectorCards(address ashCCCore) public adminRequired {
        _ashCCCore = ashCCCore;
    }

    function setAeternumToken(address aeternumAddress, uint aeternumId) public adminRequired {
        _aeternumAddress = aeternumAddress;
        _aeternumId = aeternumId;
    }

    function setSecondStateDiscounts(address secondStateAddress, uint secondStateId1, uint secondStateId2) public adminRequired {
        _secondStateAddress = secondStateAddress;
        _secondStateId1 = secondStateId1;
        _secondStateId2 = secondStateId2;
    }

    function setBatchListings(uint[] memory listingIds) public adminRequired {
        for (uint i; i < listingIds.length; i++) {
            _batchListingIds[listingIds[i]] = true;
        }
    }

    function deliver(address, uint256 listingId, uint256, address to, uint256, uint256) external override returns(uint256) {
        require((msg.sender == _marketplace || msg.sender == _discountMarketplace) &&
                (_listingIds[listingId] || _discountListingIds[listingId]),
            "Invalid call data");

        if (_discountListingIds[listingId]) {
            require(IERC1155(_aeternumAddress).balanceOf(to, _aeternumId) > 0 ||
            IERC721(_ashCCCore).balanceOf(to) > 0 ||
            IERC1155(_secondStateAddress).balanceOf(to, _secondStateId1) > 0 ||
            IERC1155(_secondStateAddress).balanceOf(to, _secondStateId2) > 0,
            "Must hold ASH Aeternum or ASH CC to mint.");
        }
        
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = to;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = _whichToken;
        uint[] memory numToSend = new uint[](1);

        if (_batchListingIds[listingId]) {
            numToSend[0] = 5;
        } else {
            numToSend[0] = 1;
        }

        if (IERC1155CreatorCore(_creator).totalSupply(_whichToken) < 1) {
            string[] memory uris = new string[](1);
            uris[0] = "";
            IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, tokenToSend, uris);
        } else {
            IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, numToSend);
        }
    }

    function setTokenURI(string memory newTokenURI) public adminRequired {
        _tokenURI = newTokenURI;
    }

    function assetURI(uint256) external view override returns(string memory) {
        return _tokenURI;
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return this.assetURI(tokenId);
    }
}
