// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/* Gambulls Exchange 2023 */

import "./OrderValidator.sol";
import "./LibOrder.sol";
import "./LibDirectTransfer.sol";

contract ExchangeUpgradeable is Initializable, OrderValidator {

    uint256 private constant UINT256_MAX = type(uint256).max;

    mapping(bytes32 => mapping(bytes => uint256)) public _fills;

    event Cancel(bytes32 hash, bytes signature);

    function __ExchangeUpgradeable_init(string memory name_, string memory version_)
    external virtual
    {
        __ExchangeUpgradeable_init_unchained(name_, version_);
    }

    function __ExchangeUpgradeable_init_unchained(string memory name_, string memory version_)
    internal initializer
    {
        __OrderValidator_init_unchained(name_, version_);
    }

    function validateFull(LibOrder.Order memory order, bytes memory signature) internal view {
        LibOrder.validateOrderTime(order);
        validate(order, signature);
    }

    function cancel(LibOrder.Order memory order, bytes memory signature) external {
        require(_msgSender() == order.maker, "not a maker");
        require(order.salt != 0, "0 salt can't be used");
        bytes32 orderHash = LibOrder.hash(order);
        _fills[orderHash][signature] = UINT256_MAX;
        emit Cancel(orderHash, signature);
    }

    function directPurchase(LibDirectTransfer.Purchase calldata direct)
    external
    payable
    nonReentrant
    {
        LibAsset.AssetType memory paymentAssetType = getPaymentAssetType(direct.paymentToken);

        LibOrder.Order memory sellOrder = LibOrder.Order(
            direct.sellOrderMaker,
            LibAsset.Asset(
                LibAsset.AssetType(
                    direct.nftAssetClass,
                    direct.nftData
                ),
                direct.sellOrderNftAmount
            ),
            address(0),
            LibAsset.Asset(
                paymentAssetType,
                direct.sellOrderPaymentAmount
            ),
            direct.sellOrderType,
            direct.sellOrderData,
            direct.sellOrderStart,
            direct.sellOrderEnd,
            direct.sellOrderSalt
        );

        LibOrder.Order memory buyOrder = LibOrder.Order(
            _msgSender(),
            LibAsset.Asset(
                paymentAssetType,
                direct.buyOrderPaymentAmount
            ),
            direct.sellOrderMaker,
            LibAsset.Asset(
                LibAsset.AssetType(
                    direct.nftAssetClass,
                    direct.nftData
                ),
                direct.buyOrderNftAmount
            ),
            LibOrder.ORDER_BUY_TYPE,
            direct.buyOrderData,
            0,
            0,
            0
        );

        validateFull(sellOrder, direct.sellOrderSignature);

        deal(sellOrder, buyOrder, direct.buyOrderPaymentAmount);
    }

    function bulkDirectPurchase(LibDirectTransfer.Purchase[] calldata purchases)
    external
    payable
    nonReentrant
    {
        for (uint i = 0; i < purchases.length; i++) {
            LibDirectTransfer.Purchase calldata direct = purchases[i];

            LibAsset.AssetType memory paymentAssetType = getPaymentAssetType(direct.paymentToken);

            LibOrder.Order memory sellOrder = LibOrder.Order(
                direct.sellOrderMaker,
                LibAsset.Asset(
                    LibAsset.AssetType(
                        direct.nftAssetClass,
                        direct.nftData
                    ),
                    direct.sellOrderNftAmount
                ),
                address(0),
                LibAsset.Asset(
                    paymentAssetType,
                    direct.sellOrderPaymentAmount
                ),
                direct.sellOrderType,
                direct.sellOrderData,
                direct.sellOrderStart,
                direct.sellOrderEnd,
                direct.sellOrderSalt
            );

            LibOrder.Order memory buyOrder = LibOrder.Order(
                _msgSender(),
                LibAsset.Asset(
                    paymentAssetType,
                    direct.buyOrderPaymentAmount
                ),
                direct.sellOrderMaker,
                LibAsset.Asset(
                    LibAsset.AssetType(
                        direct.nftAssetClass,
                        direct.nftData
                    ),
                    direct.buyOrderNftAmount
                ),
                LibOrder.ORDER_BUY_TYPE,
                direct.buyOrderData,
                0,
                0,
                0
            );

            validateFull(sellOrder, direct.sellOrderSignature);

            deal(sellOrder, buyOrder, direct.buyOrderPaymentAmount);
        }
    }

    function directAcceptOffer(LibDirectTransfer.AcceptOffer calldata direct)
    external
    nonReentrant
    {
        LibAsset.AssetType memory paymentAssetType = getPaymentAssetType(direct.paymentToken);

        LibOrder.Order memory buyOrder = LibOrder.Order(
            direct.bidOrderMaker,
            LibAsset.Asset(
                paymentAssetType,
                direct.bidOrderPaymentAmount
            ),
            address(0),
            LibAsset.Asset(
                LibAsset.AssetType(
                    direct.nftAssetClass,
                    direct.nftData
                ),
                direct.bidOrderNftAmount
            ),
            direct.bidOrderType,
            direct.bidOrderData,
            direct.bidOrderStart,
            direct.bidOrderEnd,
            direct.bidOrderSalt
        );

        LibOrder.Order memory sellOrder = LibOrder.Order(
            _msgSender(),
            LibAsset.Asset(
                LibAsset.AssetType(
                    direct.nftAssetClass,
                    direct.nftData
                ),
                direct.sellOrderNftAmount
            ),
            direct.bidOrderMaker,
            LibAsset.Asset(
                paymentAssetType,
                direct.sellOrderPaymentAmount
            ),
            LibOrder.ORDER_SELL_TYPE,
            direct.sellOrderData,
            0,
            0,
            0
        );

        validateFull(buyOrder, direct.bidOrderSignature);

        deal(buyOrder, sellOrder, direct.sellOrderPaymentAmount);
    }

    uint256[50] private __gap;
}