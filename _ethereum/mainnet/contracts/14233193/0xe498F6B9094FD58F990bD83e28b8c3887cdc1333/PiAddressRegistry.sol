// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC165.sol";
import "./Ownable.sol";

contract PiAddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice Pip contract
    address public pip;

    /// @notice PiAuction contract
    address public auction;

    /// @notice PiMarketplace contract
    address public marketplace;

    /// @notice PiBundleMarketplace contract
    address public bundleMarketplace;

    /// @notice PiNFTFactory contract
    address public factory;

    /// @notice PiNFTFactoryPrivate contract
    address public privateFactory;

    /// @notice PiArtFactory contract
    address public artFactory;

    /// @notice PiArtFactoryPrivate contract
    address public privateArtFactory;

    /// @notice PiTokenRegistry contract
    address public tokenRegistry;

    /// @notice PiPriceFeed contract
    address public priceFeed;

    /**
     @notice Update pip contract
     @dev Only admin
     */
    function updatePip(address _pip) external onlyOwner {
        require(
            IERC165(_pip).supportsInterface(INTERFACE_ID_ERC721),
            "Not ERC721"
        );
        pip = _pip;
    }

    /**
     @notice Update PiAuction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update PiMarketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     @notice Update PiBundleMarketplace contract
     @dev Only admin
     */
    function updateBundleMarketplace(address _bundleMarketplace)
        external
        onlyOwner
    {
        bundleMarketplace = _bundleMarketplace;
    }

    /**
     @notice Update PiNFTFactory contract
     @dev Only admin
     */
    function updateNFTFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /**
     @notice Update PiNFTFactoryPrivate contract
     @dev Only admin
     */
    function updateNFTFactoryPrivate(address _privateFactory)
        external
        onlyOwner
    {
        privateFactory = _privateFactory;
    }

    /**
     @notice Update PiArtFactory contract
     @dev Only admin
     */
    function updateArtFactory(address _artFactory) external onlyOwner {
        artFactory = _artFactory;
    }

    /**
     @notice Update PiArtFactoryPrivate contract
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
