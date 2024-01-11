// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./OrderLib.sol";
import "./OrderExtLib.sol";
import "./ERC2771Context.sol";
import "./MarketEscrow.sol";
import "./MarketTxValidatable.sol";

/**
 * @title MarketBase
 * MarketBase - The Market's central contract.
 */
abstract contract MarketBase is
    ERC2771Context,
    ReentrancyGuard,
    MarketEscrow,
    MarketTxValidatable
{
    using SafeMath for uint256;

    /**
     * @notice Set immutable variables for the implementation contract.
     * @dev Using immutable instead of constants allows us to use different values on testnet.
     * @param name The user readable name of the signing domain.
     * @param version The current major version of the signing domain.
     * @param trustedForwarder The Recomet TrustedForwarder address.
     */
    constructor(
        string memory name,
        string memory version,
        address trustedForwarder
    )
        EIP712(name, version)
        ERC2771Context(trustedForwarder)
        Ownable()
        ReentrancyGuard()
        AdminController(_msgSender())
    {}

    /**
     * @notice Set the price of the order and escrow to the market contract.
     * The Deposit is held in escrow until the order is finalized or canceled.
     * @param order The information of order.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of taker or forwarder.
     */
    function createOrder(
        OrderLib.OrderData memory order,
        bytes memory signatureLeft,
        bytes memory signatureRight
    ) external payable nonReentrant {
        (bool isValid, string memory errorMessage) = _validateFull(
            OrderLib.CREATE_ORDER_TYPE,
            order,
            signatureLeft,
            signatureRight
        );
        require(isValid, errorMessage);
        bytes32 orderId = OrderLib.hashKey(order);
        _createDeposit(orderId, order.taker, order.takeAsset);
    }

    /**
     * @notice Update the price of the order, refund the old currency and escrow the new currency to the market contract.
     * The Deposit is held in escrow until the order is finalized or canceled.
     * @param order The information of order.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of taker or forwarder.
     */
    function updateOrder(
        OrderLib.OrderData memory order,
        bytes memory signatureLeft,
        bytes memory signatureRight
    ) external payable nonReentrant {
        (bool isValid, string memory errorMessage) = _validateFull(
            OrderLib.UPDATE_ORDER_TYPE,
            order,
            signatureLeft,
            signatureRight
        );
        require(isValid, errorMessage);
        bytes32 orderId = OrderLib.hashKey(order);
        _updateDeposit(orderId, order.taker, order.takeAsset);
    }

    /**
     * @notice Cancel the order and refund the currency in the market contract.
     * @param order The information of order.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of taker or forwarder.
     */
    function cancelOrder(
        OrderLib.OrderData memory order,
        bytes memory signatureLeft,
        bytes memory signatureRight
    ) external nonReentrant {
        bytes32 orderId = OrderLib.hashKey(order);
        AssetLib.AssetData memory asset = getDeposit(orderId);
        if (
            asset.value != 0 &&
            asset.assetType.assetClass != bytes4(0) &&
            order.end < block.timestamp
        ) {
            (bool isValid, string memory errorMessage) = _validateOrderAndSig(
                OrderLib.CANCEL_ORDER_TYPE,
                order,
                order.taker,
                signatureRight
            );
            require(isValid, errorMessage);
        } else {
            (bool isValid, string memory errorMessage) = _validateFull(
                OrderLib.CANCEL_ORDER_TYPE,
                order,
                signatureLeft,
                signatureRight
            );
            require(isValid, errorMessage);
        }
        _withdraw(orderId, order.taker);
    }

    /**
     * @notice Finalize the order and allows for payment and NFT to be sent.
     * @param order The information of order.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of taker or forwarder.
     */
    function finalizeOrder(
        OrderLib.OrderData memory order,
        bytes memory signatureLeft,
        bytes memory signatureRight
    ) external payable nonReentrant {
        OrderExtLib.OrderExtData memory data = OrderExtLib.decodeOrderExtData(
            order.data
        );
        (bool isValid, string memory errorMessage) = _validateFull(
            OrderLib.FINALIZE_ORDER_TYPE,
            order,
            signatureLeft,
            signatureRight
        );
        require(isValid, errorMessage);
        bytes32 orderId = OrderLib.hashKey(order);
        _transfer(order.makeAsset, order.maker, order.taker);
        _pay(orderId, data.payouts, data.fees);
    }

    /**
     * @notice Get the version of order.
     */
    function getVersion() external pure returns (bytes4) {
        return OrderExtLib.VERSION;
    }

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes memory)
    {
        return super._msgData();
    }

    /**
     * @notice Verify order and signature.
     * @param orderType The type of order.
     * @param order The information of order.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of taker or forwarder.
     */
    function _validateFull(
        bytes4 orderType,
        OrderLib.OrderData memory order,
        bytes memory signatureLeft,
        bytes memory signatureRight
    ) internal view returns (bool, string memory) {
        (bool isOrderValid, string memory orderErrorMessage) = _validateOrder(
            orderType,
            order
        );
        if (!isOrderValid) {
            return (isOrderValid, orderErrorMessage);
        }
        (
            bool isMakerSigValid,
            string memory makerSigErrorMessage
        ) = _validateSig(order, order.maker, signatureLeft);
        if (!isMakerSigValid) {
            return (isMakerSigValid, makerSigErrorMessage);
        }
        (
            bool isTakerSigValid,
            string memory takerSigErrorMessage
        ) = _validateSig(order, order.taker, signatureRight);
        if (!isTakerSigValid && orderType != OrderLib.FINALIZE_ORDER_TYPE) {
            return (isTakerSigValid, takerSigErrorMessage);
        } else if (
            !isTakerSigValid && orderType == OrderLib.FINALIZE_ORDER_TYPE
        ) {
            OrderExtLib.OrderExtData memory dataExt = OrderExtLib
                .decodeOrderExtData(order.data);
            (
                bool isForwarderSigValid,
                string memory forwarderSigErrorMessage
            ) = _validateSig(order, dataExt.forwarder, signatureRight);
            if (!isForwarderSigValid) {
                return (isForwarderSigValid, forwarderSigErrorMessage);
            }
        }
        return (true, "");
    }

    /**
     * @notice Verify order and signature.
     * @param orderType The type of order.
     * @param order The information of order.
     * @param signer The address of the signer.
     * @param signature The signature of signer.
     */
    function _validateOrderAndSig(
        bytes4 orderType,
        OrderLib.OrderData memory order,
        address signer,
        bytes memory signature
    ) internal view returns (bool, string memory) {
        (bool isOrderValid, string memory orderErrorMessag) = _validateOrder(
            orderType,
            order
        );
        if (!isOrderValid) {
            return (isOrderValid, orderErrorMessag);
        }
        (bool isSigValid, string memory sigErrorMessage) = _validateSig(
            order,
            signer,
            signature
        );
        if (!isSigValid) {
            return (isSigValid, sigErrorMessage);
        }
        return (true, "");
    }

    /**
     * @notice Verify order.
     * @param orderType The type of order.
     * @param order The information of order.
     */
    function _validateOrder(bytes4 orderType, OrderLib.OrderData memory order)
        private
        view
        returns (bool, string memory)
    {
        bool isTargetOrderType = orderType == OrderLib.CREATE_ORDER_TYPE ||
            orderType == OrderLib.UPDATE_ORDER_TYPE ||
            orderType == OrderLib.FINALIZE_ORDER_TYPE;
        if (order.orderType != orderType) {
            return (false, "MarketBase: orderType verification failed");
        } else if (isTargetOrderType && order.start > block.timestamp) {
            return (false, "MarketBase: start verification failed");
        } else if (isTargetOrderType && order.end < block.timestamp) {
            return (false, "MarketBase: end verification failed");
        }
        return OrderLib.validate(order);
    }

    /**
     * @notice Verify signature.
     * @param order The information of order.
     * @param signer The address of the signer.
     * @param signature The signature of signer.
     */
    function _validateSig(
        OrderLib.OrderData memory order,
        address signer,
        bytes memory signature
    ) private view returns (bool, string memory) {
        bytes32 hash = OrderLib.hash(order);
        (bool isValid, string memory errorMessage) = _validateTx(
            signer,
            hash,
            signature
        );
        return (isValid, errorMessage);
    }
}
