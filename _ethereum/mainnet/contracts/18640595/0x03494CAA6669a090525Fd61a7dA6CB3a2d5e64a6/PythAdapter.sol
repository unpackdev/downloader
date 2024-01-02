// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./SafeCast.sol";
import "./IPyth.sol";

import "./IOracleAdapter.sol";
import "./IAddressManager.sol";
import "./IACLManager.sol";
import "./Errors.sol";

contract PythAdapter is IOracleAdapter {
    using SafeCast for uint256;

    uint8 public constant TARGET_DECIMALS = 18;

    uint8 public constant MIN_TIME_BEFORE = 4 seconds;

    uint8 public constant MAX_TIME_AFTER = 10 seconds;

    IAddressManager public immutable addressManager;

    IPyth public immutable pyth;

    mapping(address => bytes32) public assetToPriceId;

    mapping(bytes32 => address) public priceIdToAsset;

    /// @dev Asset -> Timestamp -> Price
    mapping(address => mapping(uint40 => uint128)) public assetPrices;

    /**
     * @dev Emitted when priceId is set for some asset
     * @param asset Address of the asset
     * @param priceId Pyth priceId for asset
     */
    event AssetPriceIdSet(address asset, bytes32 priceId);

    event AssetPriceUpdated(address asset, uint40 timestamp, uint128 price);

    modifier onlyCegaAdmin() {
        require(
            IACLManager(addressManager.getACLManager()).isCegaAdmin(msg.sender),
            Errors.NOT_CEGA_ADMIN
        );
        _;
    }

    constructor(IAddressManager _addressManager, IPyth _pyth) {
        addressManager = _addressManager;
        pyth = _pyth;
    }

    function getSinglePrice(
        address asset,
        uint40 timestamp
    ) external view returns (uint128) {
        uint128 price = assetPrices[asset][timestamp];
        require(price != 0, Errors.NO_PRICE_AVAILABLE);
        return price;
    }

    function getPrice(
        address baseAsset,
        address quoteAsset,
        uint40 timestamp
    ) external view returns (uint128) {
        uint128 basePrice = assetPrices[baseAsset][timestamp];
        require(basePrice != 0, Errors.NO_PRICE_AVAILABLE);

        uint128 quotePrice = assetPrices[quoteAsset][timestamp];
        require(quotePrice != 0, Errors.NO_PRICE_AVAILABLE);

        return ((basePrice * 10 ** TARGET_DECIMALS) / quotePrice).toUint128();
    }

    function setAssetPriceId(
        address asset,
        bytes32 priceId
    ) external onlyCegaAdmin {
        assetToPriceId[asset] = priceId;
        priceIdToAsset[priceId] = asset;

        emit AssetPriceIdSet(asset, priceId);
    }

    function updateAssetPrices(
        uint40 timestamp,
        address[] calldata assets,
        bytes[] calldata updateDatas
    ) external payable {
        bytes32[] memory priceIds = new bytes32[](assets.length);
        for (uint256 i = 0; i < priceIds.length; i++) {
            priceIds[i] = assetToPriceId[assets[i]];
            require(priceIds[i] != bytes32(0), Errors.NO_PRICE_FEED_SET);
        }

        PythStructs.PriceFeed[] memory priceFeeds = pyth.parsePriceFeedUpdates{
            value: msg.value
        }(
            updateDatas,
            priceIds,
            timestamp - MIN_TIME_BEFORE,
            timestamp + MAX_TIME_AFTER
        );

        for (uint256 i = 0; i < priceFeeds.length; i++) {
            address asset = priceIdToAsset[priceFeeds[i].id];
            uint128 price = _priceToUint(priceFeeds[i].price);
            assetPrices[asset][timestamp] = price;

            emit AssetPriceUpdated(asset, timestamp, price);
        }
    }

    function _priceToUint(
        PythStructs.Price memory price
    ) private pure returns (uint128) {
        if (price.price < 0 || price.expo > 0 || price.expo < -255) {
            revert(Errors.INCOMPATIBLE_PRICE);
        }

        uint8 priceDecimals = uint8(uint32(-1 * price.expo));

        if (TARGET_DECIMALS >= priceDecimals) {
            return
                (uint64(price.price) * 10 ** (TARGET_DECIMALS - priceDecimals))
                    .toUint128();
        } else {
            return
                (uint64(price.price) / 10 ** (priceDecimals - TARGET_DECIMALS))
                    .toUint128();
        }
    }
}
