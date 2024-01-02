// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IChainlinkAggregator.sol";
import "./Errors.sol";
import "./IACLManager.sol";
import "./IPoolAddressesProvider.sol";
import "./IPriceOracleGetter.sol";
import "./IYLDROracle.sol";
import "./IERC1155PriceOracle.sol";

/**
 * @title YLDROracle
 *
 * @notice Contract to get asset prices, manage price sources and update the fallback oracle
 * - Use of Chainlink Aggregators as first source of price
 * - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallback oracle
 * - Owned by the YLDR governance
 */
contract YLDROracle is IYLDROracle {
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    // Map of asset price sources (asset => priceSource)
    mapping(address => IChainlinkAggregator) private assetsSources;

    // Map of ERC1155 asset price sources (asset => priceSource)
    mapping(address => IERC1155PriceOracle) private erc1155AssetsSources;

    IPriceOracleGetter private _fallbackOracle;
    address public immutable override BASE_CURRENCY;
    uint256 public immutable override BASE_CURRENCY_UNIT;

    /**
     * @dev Only asset listing or pool admin can call functions marked by this modifier.
     */
    modifier onlyAssetListingOrPoolAdmins() {
        _onlyAssetListingOrPoolAdmins();
        _;
    }

    /**
     * @notice Constructor
     * @param provider The address of the new PoolAddressesProvider
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     * @param fallbackOracle The address of the fallback oracle to use if the data of an
     *        aggregator is not consistent
     * @param baseCurrency The base currency used for the price quotes. If USD is used, base currency is 0x0
     * @param baseCurrencyUnit The unit of the base currency
     */
    constructor(
        IPoolAddressesProvider provider,
        address[] memory assets,
        address[] memory sources,
        address[] memory erc1155Assets,
        address[] memory erc1155Sources,
        address fallbackOracle,
        address baseCurrency,
        uint256 baseCurrencyUnit
    ) {
        ADDRESSES_PROVIDER = provider;
        _setFallbackOracle(fallbackOracle);
        _setAssetsSources(assets, sources);
        _setERC1155AssetsSources(erc1155Assets, erc1155Sources);
        BASE_CURRENCY = baseCurrency;
        BASE_CURRENCY_UNIT = baseCurrencyUnit;
        emit BaseCurrencySet(baseCurrency, baseCurrencyUnit);
    }

    /// @inheritdoc IYLDROracle
    function setAssetSources(address[] calldata assets, address[] calldata sources)
        external
        override
        onlyAssetListingOrPoolAdmins
    {
        _setAssetsSources(assets, sources);
    }

    /// @inheritdoc IYLDROracle
    function setERC1155AssetSources(address[] calldata assets, address[] calldata sources)
        external
        override
        onlyAssetListingOrPoolAdmins
    {
        _setERC1155AssetsSources(assets, sources);
    }

    /// @inheritdoc IYLDROracle
    function setFallbackOracle(address fallbackOracle) external override onlyAssetListingOrPoolAdmins {
        _setFallbackOracle(fallbackOracle);
    }

    /**
     * @notice Internal function to set the sources for each asset
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     */
    function _setAssetsSources(address[] memory assets, address[] memory sources) internal {
        require(assets.length == sources.length, Errors.INCONSISTENT_PARAMS_LENGTH);
        for (uint256 i = 0; i < assets.length; i++) {
            assetsSources[assets[i]] = IChainlinkAggregator(sources[i]);
            emit AssetSourceUpdated(assets[i], sources[i]);
        }
    }

    /**
     * @notice Internal function to set the sources for each ERC1155 asset
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     */
    function _setERC1155AssetsSources(address[] memory assets, address[] memory sources) internal {
        require(assets.length == sources.length, Errors.INCONSISTENT_PARAMS_LENGTH);
        for (uint256 i = 0; i < assets.length; i++) {
            erc1155AssetsSources[assets[i]] = IERC1155PriceOracle(sources[i]);
            emit ERC1155AssetSourceUpdated(assets[i], sources[i]);
        }
    }

    /**
     * @notice Internal function to set the fallback oracle
     * @param fallbackOracle The address of the fallback oracle
     */
    function _setFallbackOracle(address fallbackOracle) internal {
        _fallbackOracle = IPriceOracleGetter(fallbackOracle);
        emit FallbackOracleUpdated(fallbackOracle);
    }

    /// @inheritdoc IPriceOracleGetter
    function getAssetPrice(address asset) public view override returns (uint256) {
        IChainlinkAggregator source = assetsSources[asset];

        if (asset == BASE_CURRENCY) {
            return BASE_CURRENCY_UNIT;
        } else if (address(source) == address(0)) {
            return _fallbackOracle.getAssetPrice(asset);
        } else {
            int256 price = source.latestAnswer();
            if (price > 0) {
                return uint256(price);
            } else {
                return _fallbackOracle.getAssetPrice(asset);
            }
        }
    }

    /// @inheritdoc IPriceOracleGetter
    function getERC1155AssetPrice(address asset, uint256 tokenId) external view returns (uint256) {
        IERC1155PriceOracle source = erc1155AssetsSources[asset];
        if (address(source) == address(0)) {
            return _fallbackOracle.getERC1155AssetPrice(asset, tokenId);
        } else {
            return source.getAssetPrice(tokenId);
        }
    }

    /// @inheritdoc IYLDROracle
    function getAssetsPrices(address[] calldata assets) external view override returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }

    /// @inheritdoc IYLDROracle
    function getSourceOfAsset(address asset) external view override returns (address) {
        return address(assetsSources[asset]);
    }

    /// @inheritdoc IYLDROracle
    function getFallbackOracle() external view returns (address) {
        return address(_fallbackOracle);
    }

    function _onlyAssetListingOrPoolAdmins() internal view {
        IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
        require(
            aclManager.isAssetListingAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
        );
    }
}
