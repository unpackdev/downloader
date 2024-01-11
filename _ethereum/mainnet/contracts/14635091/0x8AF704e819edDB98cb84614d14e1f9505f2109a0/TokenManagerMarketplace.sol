// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IERC721.sol";

abstract contract TokenManagerMarketplace is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _allowedMarketplaces;

    event MarketplaceRemoved(address indexed marketplace);
    event MarketplaceAdded(address indexed marketplace);

    modifier onlyAllowedMarketplaces() {
        require(_isMarketplaceAllowed(_msgSender()), "TokenManagerMarketplace: Only Allowed Marketplaces");
        _;
    }

    function addMarketplace(address marketplace) external onlyOwner {
        require(!_allowedMarketplaces.contains(marketplace), "TokenManagerMarketplace: Already allowed");
        _allowedMarketplaces.add(marketplace);

        emit MarketplaceAdded(marketplace);
    }

    function removeMarketplace(address marketplace) external onlyOwner {
        require(_allowedMarketplaces.contains(marketplace), "TokenManagerMarketplace: Not allowed");
        _allowedMarketplaces.remove(marketplace);

        emit MarketplaceRemoved(marketplace);
    }

    function isMarketplaceAllowed(address marketplace) external view returns (bool) {
        return _isMarketplaceAllowed(marketplace);
    }
    
    function viewCountAllowedMarketplaces() external view returns (uint256) {
        return _allowedMarketplaces.length();
    }
    
    function viewAllowedMarketplaces(uint256 cursor, uint256 size)
        external
        view
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _allowedMarketplaces.length() - cursor) {
            length = _allowedMarketplaces.length() - cursor;
        }

        address[] memory allowedMarketplaces = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            allowedMarketplaces[i] = _allowedMarketplaces.at(cursor + i);
        }

        return (allowedMarketplaces, cursor + length);
    }

    function _isMarketplaceAllowed(address marketplace) internal view returns (bool) {
        return _allowedMarketplaces.contains(marketplace);
    }
}