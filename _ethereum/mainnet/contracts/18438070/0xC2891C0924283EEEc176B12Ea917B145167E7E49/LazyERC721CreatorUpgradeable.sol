// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: VERTICAL.art

import "./ERC721CreatorUpgradeable.sol";
import "./ILazyDelivery.sol";
import "./IMarketplaceCore.sol";

contract LazyERC721CreatorUpgradeable is ERC721CreatorUpgradeable, ILazyDelivery {
    mapping(address => bool) public authorized;

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721CreatorUpgradeable, IERC165) returns (bool) {
        return
            ERC721CreatorUpgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(ILazyDelivery).interfaceId;
    }

    function setAuthorizedThirdparty(address _party) external onlyOwner {
        authorized[_party] = true;
    }

    function deliver(
        uint40 listingId,
        address to,
        uint256 tokenId,
        uint24 count,
        uint256, // payableAmount,
        address, // payableERC20,
        uint256 // index
    ) external override {
        require(count == 1, "invalid count!");
        require(authorized[msg.sender], "unauthorized");

        IMarketplaceCore.Listing memory listing = IMarketplaceCore(msg.sender).getListing(
            listingId
        );
        require(listing.seller == owner(), "only owner can list lazy mint");

        _mintBase(to, "", tokenId);
    }
}
