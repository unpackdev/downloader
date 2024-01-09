// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./ILazyDelivery.sol";
import "./ILazyDeliveryMetadata.sol";
import "./IAshCC.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./EnumerableSet.sol";
import "./DefaultReverseResolver.sol";

/**
 * The collector card, for ASH
 */
contract AshCC is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata, IAshCC {

    using Strings for uint256;
    using Strings for uint16;

    address public _creator;
    string private _baseURI;

    mapping(uint => uint) public cardPoints;

    address private _marketplace;
    uint private _listingId;
    string private _previewImage;

    DefaultReverseResolver resolver = DefaultReverseResolver(0xA2C122BE93b0074270ebeE7f6b7292C7deB45047);

    ReverseRegistrar reverseReg = ReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);

    mapping(address => uint) merchantDiscounts;

    constructor(address creator) {
        _creator = creator;
    }

    /**
      Used for transferring points from one card to another
      Say you buy card on secondary and want to consolidate points
     */
    function transferPoints(uint cardFrom, uint cardTo, uint numPoints) public override {
      require(IERC721(_creator).ownerOf(cardFrom) == msg.sender, "Can only transfer points from own card.");
      require(cardPoints[cardFrom] >= numPoints, "Not enough points to transfer");

      cardPoints[cardFrom] = cardPoints[cardFrom] - numPoints;
      cardPoints[cardTo] = cardPoints[cardTo] + numPoints;
    }

    /**
      Add a merchant to the ecosystem. Merchants are allowed to add points
     */
    function addMerchant(address merchant, uint discountPercent) public override adminRequired {
      require(merchantDiscounts[merchant] == 0, "Cannot add merchant again.");
      merchantDiscounts[merchant] = discountPercent;
    }

    /**
      Update existing merchant
     */
    function updateMerchant(address merchant, uint discountPercent) public override adminRequired {
      require(merchantDiscounts[merchant] != 0, "Cannot update non-existent merchant.");
      merchantDiscounts[merchant] = discountPercent;
    }

    function removeMerchant(address merchant) public override adminRequired {
      require(merchantDiscounts[merchant] != 0, "Cannot remove non-existent merchant.");
      merchantDiscounts[merchant] = 0;
    }

    function addPoints(uint tokenId, uint numPoints) public override {
      require(merchantDiscounts[msg.sender] != 0, "Only approved merchant can add points.");
      cardPoints[tokenId] += numPoints;
    }

    function getDiscount(address merchant) public view override returns (uint) {
      return merchantDiscounts[merchant];
    }

    function getPoints(uint tokenId) public view override returns (uint) {
      return cardPoints[tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IAshCC).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function premint(address to, uint num, uint points) public adminRequired {
        for (uint256 i = 0; i < num; i++) {
            uint card = IERC721CreatorCore(_creator).mintExtension(to);
            cardPoints[card] = points;
        }
    }

    function setListing(uint listingId, address marketplace) public adminRequired {
        _listingId = listingId;
        _marketplace = marketplace;
    }

    function deliver(address, uint256 listingId, uint256 assetId, address to, uint256, uint256 index) external override returns(uint256) {
        require(msg.sender == _marketplace &&
                    listingId == _listingId &&
                    assetId == 1 && index == 0,
            "Invalid call data");
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

    function setBaseURI(string memory baseURI) public adminRequired {
      _baseURI = baseURI;
    }

    function getAnimationURL(uint assetId) private view returns (string memory) {
        string memory name = resolver.name(reverseReg.node(
          IERC721(_creator).ownerOf(assetId)
        ));
        return string(abi.encodePacked(_baseURI, "?id=", assetId.toString(), "&name=", name, "&points=", cardPoints[assetId].toString()));
    }

    function setPreviewImageForAll(string memory previewImage) public adminRequired {
        _previewImage = previewImage;
    }

    function assetURI(uint256 assetId) external view override returns(string memory) {
      return string(abi.encodePacked('data:application/json;utf8,',
        '{"name":"ASH Collector Card #',
        assetId.toString(),
        '","created_by":"yung wknd","description":"Reward the bold.","animation":"',
        getAnimationURL(assetId),
        '","animation_url":"',
        getAnimationURL(assetId),
        '","image":"',
        _previewImage,
        '","image_url":"',
        _previewImage,
        '","attributes":[{"trait_type":"Points","value":"',
        cardPoints[assetId].toString(),
        '"}]}'));
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return this.assetURI(tokenId);
    }
}
