// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC165.sol";
import "./Ownable.sol";

contract XanaAddressRegistry is Ownable {
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /// @notice Xana contract
    address public xana;

    /// @notice XanaAuction contract
    address public auction;

    /// @notice XanaMarketplace contract
    address public marketplace;

    /// @notice XanaBundleMarketplace contract
    address public bundleMarketplace;

    /// @notice XanaNFTFactory contract
    address public factory;

    /// @notice XanaNFTFactoryPrivate contract
    address public privateFactory;

    /// @notice XanaArtFactory contract
    address public artFactory;

    /// @notice XanaArtFactoryPrivate contract
    address public privateArtFactory;

    /// @notice XanaTokenRegistry contract
    address public tokenRegistry;

    /// @notice XanaPriceFeed contract
    address public priceFeed;

    /**
     @notice Update xana contract
     @dev Only admin
     */
    function updateXana(address _xana) external onlyOwner {
        require(
            IERC165(_xana).supportsInterface(INTERFACE_ID_ERC721),
            "Not ERC721"
        );
        xana = _xana;
    }

    /**
     @notice Update XanaAuction contract
     @dev Only admin
     */
    function updateAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    /**
     @notice Update XanaMarketplace contract
     @dev Only admin
     */
    function updateMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    /**
     @notice Update XanaBundleMarketplace contract
     @dev Only admin
     */
    function updateBundleMarketplace(address _bundleMarketplace)
        external
        onlyOwner
    {
        bundleMarketplace = _bundleMarketplace;
    }

    /**
     @notice Update XanaNFTFactory contract
     @dev Only admin
     */
    function updateNFTFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    /**
     @notice Update XanaNFTFactoryPrivate contract
     @dev Only admin
     */
    function updateNFTFactoryPrivate(address _privateFactory)
        external
        onlyOwner
    {
        privateFactory = _privateFactory;
    }

    /**
     @notice Update XanaArtFactory contract
     @dev Only admin
     */
    function updateArtFactory(address _artFactory) external onlyOwner {
        artFactory = _artFactory;
    }

    /**
     @notice Update XanaArtFactoryPrivate contract
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
