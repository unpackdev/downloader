// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC165.sol";
import "./Ownable.sol";

contract AddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice Grapes contract
    address public grapes;

    /// @notice Auction contract
    address public auction;

    /// @notice Marketplace contract
    address public marketplace;

    /// @notice BundleMarketplace contract
    address public bundleMarketplace;

    /// @notice NFTFactory contract
    address public factory;

    /// @notice NFTFactoryPrivate contract
    address public privateFactory;

    /// @notice ArtFactory contract
    address public artFactory;

    /// @notice ArtFactoryPrivate contract
    address public privateArtFactory;

    /// @notice TokenRegistry contract
    address public tokenRegistry;

    /// @notice PriceFeed contract
    address public priceFeed;

    /**
     @notice Update grapes contract
     @dev Only admin
     */
    function updateGrapes(address _grapes) external onlyOwner {
        require(
            IERC165(_grapes).supportsInterface(INTERFACE_ID_ERC721),
            "Not ERC721"
        );
        grapes = _grapes;
    }

    /**
     @notice Update Auction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update Marketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     @notice Update BundleMarketplace contract
     @dev Only admin
     */
    function updateBundleMarketplace(address _bundleMarketplace)
        external
        onlyOwner
    {
        bundleMarketplace = _bundleMarketplace;
    }

    /**
     @notice Update NFTFactory contract
     @dev Only admin
     */
    function updateNFTFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /**
     @notice Update NFTFactoryPrivate contract
     @dev Only admin
     */
    function updateNFTFactoryPrivate(address _privateFactory)
        external
        onlyOwner
    {
        privateFactory = _privateFactory;
    }

    /**
     @notice Update ArtFactory contract
     @dev Only admin
     */
    function updateArtFactory(address _artFactory) external onlyOwner {
        artFactory = _artFactory;
    }

    /**
     @notice Update ArtFactoryPrivate contract
     @dev Only admin
     */
    function updateArtFactoryPrivate(address _privateArtFactory)
        external
        onlyOwner
    {
        privateArtFactory = _privateArtFactory;
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
