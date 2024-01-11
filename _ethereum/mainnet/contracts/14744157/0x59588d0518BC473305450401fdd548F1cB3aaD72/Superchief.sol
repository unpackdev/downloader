// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC1155CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC1155.sol";
import "./ERC165.sol";

interface ILazyDelivery is IERC165 {
    function deliver(address caller, uint256 listingId, uint256 assetId, address to, uint256 payableAmount, uint256 index) external returns(uint256);
}

interface ILazyDeliveryMetadata is IERC165 {
    function assetURI(uint256 assetId) external view returns(string memory);
}

contract Superchief is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {
    address private _creator;
    address private _marketplace;
    uint private _listingId;

    string private _assetURI;
    bool private _presaleOn;

    mapping(address => bool) preMinters;

    constructor(address creator) {
        _creator = creator;
    }

    function preMint(address[] memory receivers) public adminRequired {
        address[] memory addressToSend = new address[](1);
        addressToSend = receivers;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 1;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = 1;

        IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, amounts);
    }

    function initialize() public adminRequired {
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 1;
        string[] memory uris = new string[](1);
        uris[0] = "";

        IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, amounts, uris);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setPresaleOn(bool presaleOn) public adminRequired {
      _presaleOn = presaleOn;
    }

    function setPresaleMinters(address[] memory minters) public adminRequired {
      for (uint i = 0; i < minters.length; i++) {
        preMinters[minters[i]] = true;
      }
    }

    function setListing(uint listingId, address marketplace) public adminRequired {
        _listingId = listingId;
        _marketplace = marketplace;
    }

    function deliver(address, uint256 listingId, uint256, address to, uint256, uint256) external override returns(uint256) {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid call data");

        if (_presaleOn) {
          require(preMinters[to], "Not on presale list");
          preMinters[to] = false;
        }

        address[] memory addressToSend = new address[](1);
        addressToSend[0] = to;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = 1;
        uint[] memory amounts = new uint[](1);
        amounts[0] = 1;

        IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, amounts);

        return 1;
    }

    function setNewAssetURI(string memory newAssetURI) public adminRequired {
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
