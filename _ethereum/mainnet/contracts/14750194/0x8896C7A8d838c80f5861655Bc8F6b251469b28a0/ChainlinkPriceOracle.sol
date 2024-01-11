// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./IAccessControl.sol";
import "./ERC165.sol";
import "./ERC165Checker.sol";
import "./IERC20Metadata.sol";
import "./AggregatorV2V3Interface.sol";

import "./FullMath.sol";
import "./FixedPoint112.sol";

import "./IChainlinkPriceOracle.sol";

/// @title Chainlink price oracle
/// @notice Contains logic for getting asset's price from Chainlink data feed
/// @dev Oracle works through base asset which is set in initialize function
contract ChainlinkPriceOracle is IChainlinkPriceOracle, ERC165 {
    using FullMath for uint;
    using ERC165Checker for address;

    struct AssetInfo {
        address[] aggregators;
        uint8 decimals;
    }

    /// @notice Role allows configure asset related data/components
    bytes32 internal immutable ASSET_MANAGER_ROLE;

    /// @notice Infos of added assets
    mapping(address => AssetInfo) internal assetInfoOf;

    /// @notice Index registry address
    IAccessControl internal immutable registry;

    /// @notice Chainlink aggregator for the base asset
    AggregatorV2V3Interface internal immutable baseAggregator;

    /// @notice Number of decimals in base asset
    uint8 internal immutable baseDecimals;

    /// @notice Number of decimals in base asset answer
    uint8 internal immutable baseAnswerDecimals;

    /// @notice Number of decimals in answer of aggregator
    mapping(address => uint) internal answerDecimals;

    /// @inheritdoc IPriceOracle
    mapping(address => uint) public override lastAssetPerBaseInUQ;

    /// @inheritdoc IChainlinkPriceOracle
    uint public maxUpdateInterval;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "ChainlinkPriceOracle: FORBIDDEN");
        _;
    }

    constructor(
        address _registry,
        address _base,
        address _baseAggregator,
        uint _maxUpdateInterval
    ) {
        require(_base != address(0) && _baseAggregator != address(0), "ChainlinkPriceOracle: ZERO");
        require(_registry.supportsInterface(type(IAccessControl).interfaceId), "ChainlinkPriceOracle: INTERFACE");

        ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

        registry = IAccessControl(_registry);
        baseAnswerDecimals = AggregatorV2V3Interface(_baseAggregator).decimals();
        baseDecimals = IERC20Metadata(_base).decimals();
        baseAggregator = AggregatorV2V3Interface(_baseAggregator);
        maxUpdateInterval = _maxUpdateInterval;
    }

    /// @inheritdoc IChainlinkPriceOracle
    function setMaxUpdateInterval(uint _maxUpdateInterval) external override onlyRole(ASSET_MANAGER_ROLE) {
        maxUpdateInterval = _maxUpdateInterval;
        emit SetMaxUpdateInterval(msg.sender, _maxUpdateInterval);
    }

    /// @inheritdoc IChainlinkPriceOracle
    function addAsset(address _asset, address _assetAggregator) external override onlyRole(ASSET_MANAGER_ROLE) {
        require(_asset != address(0), "ChainlinkPriceOracle: ZERO");

        address[] memory aggregators = new address[](1);
        aggregators[0] = _assetAggregator;

        assetInfoOf[_asset] = AssetInfo({ aggregators: aggregators, decimals: IERC20Metadata(_asset).decimals() });
        answerDecimals[_assetAggregator] = AggregatorV2V3Interface(_assetAggregator).decimals();

        emit AssetAdded(_asset, aggregators);

        refreshedAssetPerBaseInUQ(_asset);
        require(lastAssetPerBaseInUQ[_asset] != 0, "ChainlinkPriceOracle: PRICE");
    }

    /// @inheritdoc IChainlinkPriceOracle
    function addAsset(address _asset, address[] memory _assetAggregators)
        external
        override
        onlyRole(ASSET_MANAGER_ROLE)
    {
        uint aggregatorsCount = _assetAggregators.length;
        require(_asset != address(0) && aggregatorsCount != 0, "ChainlinkPriceOracle: INVALID");

        assetInfoOf[_asset] = AssetInfo({
            aggregators: _assetAggregators,
            decimals: IERC20Metadata(_asset).decimals()
        });

        for (uint i; i < aggregatorsCount; ) {
            address aggregator = _assetAggregators[i];

            answerDecimals[aggregator] = AggregatorV2V3Interface(aggregator).decimals();

            unchecked {
                i = i + 1;
            }
        }

        emit AssetAdded(_asset, _assetAggregators);

        refreshedAssetPerBaseInUQ(_asset);
        require(lastAssetPerBaseInUQ[_asset] != 0, "ChainlinkPriceOracle: PRICE");
    }

    /// @inheritdoc IPriceOracle
    function refreshedAssetPerBaseInUQ(address _asset) public override returns (uint) {
        AssetInfo storage assetInfo = assetInfoOf[_asset];

        uint _basePrice;
        {
            (uint80 baseRoundID, int basePrice, , uint baseUpdatedAt, uint80 baseAnsweredInRound) = baseAggregator
                .latestRoundData();
            if (baseUpdatedAt == 0 || basePrice < 1 || baseAnsweredInRound < baseRoundID) {
                return lastAssetPerBaseInUQ[_asset];
            }
            require(maxUpdateInterval > block.timestamp - baseUpdatedAt, "ChainlinkPriceOracle: INTERVAL");

            _basePrice = uint(basePrice);
        }

        uint assetPerBaseInUQ;

        uint aggregatorsCount = assetInfo.aggregators.length;
        for (uint i; i < aggregatorsCount; ) {
            address aggregator = assetInfo.aggregators[i];

            (
                uint80 quoteRoundID,
                int quotePrice,
                ,
                uint quoteUpdatedAt,
                uint80 quoteAnsweredInRound
            ) = AggregatorV2V3Interface(aggregator).latestRoundData();
            if (quoteUpdatedAt == 0 || quotePrice < 1 || quoteAnsweredInRound < quoteRoundID) {
                return lastAssetPerBaseInUQ[_asset];
            }
            require(maxUpdateInterval > block.timestamp - quoteUpdatedAt, "ChainlinkPriceOracle: INTERVAL");

            if (i == 0) {
                assetPerBaseInUQ =
                    ((10**assetInfo.decimals * _basePrice).mulDiv(
                        FixedPoint112.Q112,
                        uint(quotePrice) * 10**baseDecimals
                    ) * 10**answerDecimals[aggregator]) /
                    10**baseAnswerDecimals;
            } else {
                assetPerBaseInUQ = (assetPerBaseInUQ / uint(quotePrice)) * 10**answerDecimals[aggregator];
            }

            unchecked {
                i = i + 1;
            }
        }

        lastAssetPerBaseInUQ[_asset] = assetPerBaseInUQ;

        return assetPerBaseInUQ;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IChainlinkPriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}
