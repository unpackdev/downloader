//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AdminControl.sol";
import "./IERC1155CreatorCore.sol";

interface ILazyDelivery is IERC165 {
    function deliver(address caller, uint256 listingId, uint256 assetId, address to, uint256 payableAmount, uint256 index) external returns(uint256);
}

interface ILazyDeliveryMetadata is IERC165 {
    function assetURI(uint256 assetId) external view returns(string memory);
}

contract ImpactTwo is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {
    address public _creator;
    uint public _tokenId;
    uint public _amountPerSale;

    address private _marketplace;
    uint private _listingId;

    mapping(uint => string) _assetURIs;

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

    function deliver(address, uint256 listingId, uint256, address to, uint256, uint256) external override returns(uint256) {
        require(msg.sender == _marketplace &&
                    listingId == _listingId,
            "Invalid call data");

        address[] memory callerAddresses = new address[](1);
        uint256[] memory tokenIdsForMint = new uint256[](1);
        uint256[] memory amountsForMint = new uint256[](1);

        callerAddresses[0] = to;
        tokenIdsForMint[0] = _tokenId;
        amountsForMint[0] = _amountPerSale;

        IERC1155CreatorCore(_creator).mintExtensionExisting(callerAddresses, tokenIdsForMint, amountsForMint);
    }

    function mintNewTokenAsAdmin() external adminRequired {
        address[] memory callerAddresses = new address[](1);
        uint256[] memory amountsForMint = new uint256[](1);
        string[] memory uris = new string[](1);

        callerAddresses[0] = msg.sender;
        amountsForMint[0] = _amountPerSale;
        uris[0] = "";

        IERC1155CreatorCore(_creator).mintExtensionNew(callerAddresses, amountsForMint, uris);
    }

    function assetURI(uint256 tokenId) external view override returns(string memory) {
        return _assetURIs[tokenId];
    }

    function setTokenInfo(uint8 tokenId, string memory newAssetURI, uint amountPerSale) external adminRequired {
        _tokenId = tokenId;
        _amountPerSale = amountPerSale;
        _assetURIs[tokenId] = newAssetURI;
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return this.assetURI(tokenId);
    }
}