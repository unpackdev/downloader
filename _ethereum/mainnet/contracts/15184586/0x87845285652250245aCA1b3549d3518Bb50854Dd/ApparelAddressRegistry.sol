// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./Ownable.sol";

contract ApparelAddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice Auction contract
    address public auction;

    /// @notice Marketplace contract
    address public marketplace;

    /// @notice NFTFactory contract
    address public nftFactory;

    /// @notice ArtFactory contract
    address public artFactory;

    /// @notice TokenRegistry contract
    address public tokenRegistry;

    /// @notice PriceFeed contract
    address public priceFeed;

    /**
     @notice Update Marketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     @notice Update Auction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update NFTFactory contract
     @dev Only admin
     */
    function updateNFTFactory(address _factory) external onlyOwner {
        nftFactory = _factory;
    }

    /**
     @notice Update ArtFactory contract
     @dev Only admin
     */
    function updateArtFactory(address _factory) external onlyOwner {
        artFactory = _factory;
    }

    /**
     @notice Update token registry contract
     @dev Only admin
     */
    function updateTokenRegistry(address _tokenRegistry) external onlyOwner {
        tokenRegistry = _tokenRegistry;
    }

    /**
     @notice Update price feed contract
     @dev Only admin
     */
    function updatePriceFeed(address _priceFeed) external onlyOwner {
        priceFeed = _priceFeed;
    }
}