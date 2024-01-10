// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Timpers
/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC1155CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./ILazyDelivery.sol";
import "./ILazyDeliveryMetadata.sol";

import "./IERC1155.sol";
import "./ERC165.sol";

contract eBook is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {

    address private _creator;
    address private _marketplace;
    string private _assetURI;
    uint private _listingId;
    uint private _whichToken;

    mapping(address => uint8) minters;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setListing(uint listingId, address marketplace, uint whichToken) public adminRequired {
        _listingId = listingId;
        _marketplace = marketplace;
        _whichToken = whichToken;
    }

    function premint(address[] memory to, uint[] memory num) public adminRequired {
      for (uint i = 0; i < to.length; i++) {
          address[] memory addressToSend = new address[](1);
          addressToSend[0] = to[i];
          uint[] memory tokenToSend = new uint[](1);
          tokenToSend[0] = _whichToken;
          uint[] memory numToSend = new uint[](1);
          numToSend[0] = num[i];
          string[] memory uris = new string[](1);
          uris[0] = "";

          if (IERC1155CreatorCore(_creator).totalSupply(_whichToken) > 0) {
              IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, numToSend);
          } else {
              IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, numToSend, uris);
          }
      }
    }

    function deliver(address, uint256 listingId, uint256 assetId, address to, uint256, uint256 index) external override returns(uint256) {
        require(msg.sender == _marketplace &&
                    listingId == _listingId &&
                    assetId == 1 && index == 0,
            "Invalid call data");
     
        require(minters[to] < 1, "You can only mint once.");

        minters[to]++;

        address[] memory addressToSend = new address[](1);
        addressToSend[0] = to;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = _whichToken;
        uint[] memory numToSend = new uint[](1);
        numToSend[0] = 1;

        IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, numToSend);
    }

    function setAssetURI(string memory newAssetURI) public adminRequired {
        _assetURI = newAssetURI;
    }

    function assetURI(uint256) external view override returns(string memory) {
        return _assetURI;
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return this.assetURI(tokenId);
    }
}
