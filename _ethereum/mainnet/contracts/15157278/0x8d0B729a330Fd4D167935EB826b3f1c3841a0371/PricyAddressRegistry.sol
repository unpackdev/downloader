// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IERC165.sol";
import "./Ownable.sol";

contract PricyAddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice Pricy contract
    address public pricy;

    /// @notice PricyAuction contract
    address public auction;

    /// @notice PricyMarketplace contract
    address public marketplace;

    /// @notice PricyNFTFactory contract
    address public factory;

    /// @notice PricyNFTFactoryPrivate contract
    address public privateFactory;

    /// @notice PricyArtFactory contract
    address public artFactory;

    /// @notice PricyArtFactoryPrivate contract
    address public privateArtFactory;

    /// @notice PricyTokenRegistry contract
    address public tokenRegistry;

    /// @notice PricyPriceFeed contract
    address public priceFeed;

    /**
     @notice Update pricy contract
     @dev Only admin
     */
    function updatePricy(address _pricy) external onlyOwner {
        require(
            IERC165(_pricy).supportsInterface(INTERFACE_ID_ERC721),
            "Not ERC721"
        );
        pricy = _pricy;
    }

    /**
     @notice Update PricyAuction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update PricyMarketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     @notice Update PricyNFTFactory contract
     @dev Only admin
     */
    function updateNFTFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /**
     @notice Update PricyNFTFactoryPrivate contract
     @dev Only admin
     */
    function updateNFTFactoryPrivate(address _privateFactory)
        external
        onlyOwner
    {
        privateFactory = _privateFactory;
    }

    /**
     @notice Update PricyArtFactory contract
     @dev Only admin
     */
    function updateArtFactory(address _artFactory) external onlyOwner {
        artFactory = _artFactory;
    }

    /**
     @notice Update PricyArtFactoryPrivate contract
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
