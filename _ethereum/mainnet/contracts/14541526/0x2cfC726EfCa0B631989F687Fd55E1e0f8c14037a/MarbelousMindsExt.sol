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

interface IAshCC is IERC165 {
    function addPoints(uint tokenId, uint numPoints) external;
}

contract MarbelousMindsExt is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {

    using Strings for uint256;

    address private _creator;
    string private _baseURI;

    address private _marketplace;
    uint private _listingId;

    IAshCC _ashCC;
    address _ashCCCore;

    mapping(address => uint) minters;

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

    function setRewardsCard(address ashCC, address ashCCCore) public adminRequired {
      _ashCC = IAshCC(ashCC);
      _ashCCCore = ashCCCore;
    }

    function deliver(address, uint256 listingId, uint256, address to, uint256, uint256) external override returns(uint256) {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid call data");

        require(minters[to] < 3, "Can only mint up to 3");
        minters[to]++;
        IERC721CreatorCore(_creator).mintExtension(to);

        if (IERC721(_ashCCCore).balanceOf(to) > 0) {
            for (uint i = 1; i <= 25; i++) {
                if (IERC721(_ashCCCore).ownerOf(i) == to) {
                    _ashCC.addPoints(i, 10);
                    return 0;
                }
            }
        }
        return 0;
    }

    function setBaseURI(string memory baseURI) public adminRequired {
      _baseURI = baseURI;
    }

    function assetURI(uint256 assetId) external view override returns(string memory) {
        return string(abi.encodePacked(_baseURI, assetId.toString()));
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return this.assetURI(tokenId);
    }
}