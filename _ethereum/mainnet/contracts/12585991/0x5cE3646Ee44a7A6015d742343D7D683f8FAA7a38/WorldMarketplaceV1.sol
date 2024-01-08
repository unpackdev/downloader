// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeERC20.sol";
import "./draft-EIP712.sol";
import "./BaseWorldMarketplace.sol";

contract WorldMarketplaceV1 is BaseWorldMarketplace, EIP712 {
    using SafeERC20 for IERC20;

    IERC20 public immutable WORLD;
    address public taxRecipient;

    uint256 public taxPercentage = 30;

    bytes32 private payNFTOrderTypeHash = keccak256("Order(string label,uint256 listingId,uint256 orderId,address buyer,address seller,uint256 total,address nftAddress,uint256 nftId,uint256 nftQuantity,uint256 paymentDueTime,uint256 functionId)");
    bytes32 private payOrderTypeHash = keccak256("Order(string label,uint256 listingId,uint256 orderId,address buyer,address seller,uint256 total,uint256 disputeWindow,uint256 paymentDueTime,uint256 functionId)");
    bytes32 private releasePaymentWithMessageHash = keccak256("Order(string label,uint256 listingId,uint256 orderId,uint256 functionId)");
    bytes32 private refundBuyerWithMessageHash = keccak256("Order(string label,uint256 listingId,uint256 orderId,uint256 functionId)");
    bytes32 private resolveDisputeHash = keccak256("Order(string label,uint256 listingId,uint256 orderId,bool refundBuyer,uint256 functionId)");

    constructor(address _world) EIP712("World Marketplace", "1") {
        require(_world != address(0), "_world != 0x");
        WORLD = IERC20(_world);

        isJudgeRegistrant[msg.sender] = true;
        isMerchantRegistrant[msg.sender] = true;
    }

    function _releasePaymentToSeller(address _seller, uint256 _total) internal {
        if (taxRecipient == address(0)) {
            WORLD.transfer(_seller, _total);
            return;
        }

        uint256 tax = (_total * taxPercentage) / 1000;
        WORLD.transfer(taxRecipient, tax);

        uint256 taxedTotal = _total - tax;
        WORLD.transfer(_seller, taxedTotal);
    }

    function payNFTOrder(
        string memory _label,
        uint256 _listingId,
        uint256 _orderId,
        address _seller,
        uint256 _total,
        address _nftAddress,
        uint256 _nftId,
        uint256 _nftQuantity,
        bytes memory _nftData,
        bool _nftIsErc721,
        uint256 _paymentDueTime,
        bytes memory _acceptMessage
    ) external {
        require(_total > 0, "Total is less than 1");
        require(block.timestamp <= _paymentDueTime, "Order can't be paid anymore as it's passed due");

        bytes32 messageHash = _hashTypedDataV4(keccak256(abi.encode(
                payNFTOrderTypeHash,
                keccak256(bytes(_label)),
                _listingId,
                _orderId,
                msg.sender,
                _seller,
                _total,
                _nftAddress,
                _nftId,
                _nftQuantity,
                _paymentDueTime,
                1
            )));
        address recoveredAddress = ECDSA.recover(messageHash, _acceptMessage);
        require(_seller == recoveredAddress, "Order payment is not allowed by the seller");

        Order storage order = listingOrders[_listingId][_orderId];
        require(order.status == OrderStatus.UNDEFINED, "Order is already paid");

        order.id = _orderId;
        order.listingId = _listingId;
        order.status = OrderStatus.PAYMENT_RELEASED;
        order.total = _total;
        order.buyer = msg.sender;
        order.seller = _seller;

        if (_nftIsErc721) {
            IERC721(_nftAddress).safeTransferFrom(_seller, msg.sender, _nftId, _nftData);
        } else {
            IERC1155(_nftAddress).safeTransferFrom(_seller, msg.sender, _nftId, _nftQuantity, _nftData);
        }

        WORLD.safeTransferFrom(msg.sender, address(this), _total);
        _releasePaymentToSeller(order.seller, _total);
    }

    function payOrder(
        string memory _label,
        uint256 _listingId,
        uint256 _orderId,
        address _seller,
        uint256 _total,
        uint256 _disputeWindow,
        uint256 _paymentDueTime,
        bytes memory _acceptMessage
    ) external {
        require(_total > 0, "Total is less than 1");
        require(block.timestamp <= _paymentDueTime, "Order can't be paid anymore as it's past due");
        require(isMerchant[_seller], "Seller is not recognized");

        bytes32 messageHash = _hashTypedDataV4(keccak256(abi.encode(
                payOrderTypeHash,
                keccak256(bytes(_label)),
                _listingId,
                _orderId,
                msg.sender,
                _seller,
                _total,
                _disputeWindow,
                _paymentDueTime,
                2
            )));
        address recoveredAddress = ECDSA.recover(messageHash, _acceptMessage);
        require(_seller == recoveredAddress, "Order payment is not allowed by the seller");

        Order storage order = listingOrders[_listingId][_orderId];
        require(order.status == OrderStatus.UNDEFINED, "Order is already paid");

        order.id = _orderId;
        order.listingId = _listingId;
        order.status = OrderStatus.PAID;
        order.total = _total;
        order.buyer = msg.sender;
        order.seller = _seller;
        order.acceptMessage = _acceptMessage;
        order.indisputableTime = block.timestamp + _disputeWindow;

        WORLD.safeTransferFrom(msg.sender, address(this), _total);
    }

    function releasePayment(uint256 _listingId, uint256 _orderId) external {
        Order storage order = listingOrders[_listingId][_orderId];
        require(
            order.status == OrderStatus.PAID || order.status == OrderStatus.IN_DISPUTE,
            "Order is not yet paid or is not in dispute"
        );

        if (block.timestamp <= order.indisputableTime || order.status == OrderStatus.IN_DISPUTE) {
            require(
                msg.sender == order.buyer,
                "Only buyer can release the payment if order is still disputable or is in dispute"
            );
        } else {
            require(
                msg.sender == order.buyer || msg.sender == order.seller,
                "Account is not the buyer or seller"
            );
        }

        order.status = OrderStatus.PAYMENT_RELEASED;
        _releasePaymentToSeller(order.seller, order.total);
    }

    function releasePaymentWithMessage(
        string memory _label,
        uint256 _listingId,
        uint256 _orderId,
        bytes memory _releaseMessage
    ) external {
        Order storage order = listingOrders[_listingId][_orderId];
        require(
            order.status == OrderStatus.PAID || order.status == OrderStatus.IN_DISPUTE,
            "Order is not yet paid or is not in dispute"
        );
        require(msg.sender == order.seller, "Account is not the seller");

        bytes32 messageHash = _hashTypedDataV4(keccak256(abi.encode(
                releasePaymentWithMessageHash,
                keccak256(bytes(_label)),
                _listingId,
                _orderId,
                3
            )));
        address recoveredAddress = ECDSA.recover(messageHash, _releaseMessage);
        require(order.buyer == recoveredAddress, "Payment release is not allowed by the buyer");

        order.status = OrderStatus.PAYMENT_RELEASED;
        _releasePaymentToSeller(order.seller, order.total);
    }

    function refundBuyer(uint256 _listingId, uint256 _orderId) external {
        Order storage order = listingOrders[_listingId][_orderId];
        require(msg.sender == order.seller, "Account is not the seller");
        require(
            order.status == OrderStatus.PAID || order.status == OrderStatus.IN_DISPUTE,
            "Order is not yet paid or is not in dispute"
        );

        order.status = OrderStatus.BUYER_REFUNDED;
        WORLD.transfer(order.buyer, order.total);
    }

    function refundBuyerWithMessage(
        string memory _label,
        uint256 _listingId,
        uint256 _orderId,
        bytes memory _refundMessage
    ) external {
        Order storage order = listingOrders[_listingId][_orderId];
        require(msg.sender == order.buyer, "Account is not the buyer");
        require(
            order.status == OrderStatus.PAID || order.status == OrderStatus.IN_DISPUTE,
            "Order is not yet paid or is not in dispute"
        );

        bytes32 messageHash = _hashTypedDataV4(keccak256(abi.encode(
                refundBuyerWithMessageHash,
                keccak256(bytes(_label)),
                _listingId,
                _orderId,
                4
            )));
        address recoveredAddress = ECDSA.recover(messageHash, _refundMessage);
        require(order.seller == recoveredAddress, "Refund is not allowed by the seller");

        order.status = OrderStatus.BUYER_REFUNDED;
        WORLD.transfer(order.buyer, order.total);
    }

    function fileDispute(uint256 _listingId, uint256 _orderId) external {
        Order storage order = listingOrders[_listingId][_orderId];
        require(order.status == OrderStatus.PAID, "Order is either not paid yet or already in dispute");
        require(msg.sender == order.buyer, "Account is not the buyer");
        require(block.timestamp <= order.indisputableTime, "Order is already indisputable");

        order.status = OrderStatus.IN_DISPUTE;
    }

    function resolveDispute(
        string memory _label,
        uint256 _listingId,
        uint256 _orderId,
        bool _refundBuyer,
        bytes memory _resolutionMessage
    ) external {
        Order storage order = listingOrders[_listingId][_orderId];
        require(order.status == OrderStatus.IN_DISPUTE, "Order is not in dispute or dispute is already resolved");
        require(
            msg.sender == order.buyer || msg.sender == order.seller || isJudge[msg.sender],
            "Account is not the buyer, seller, or judge"
        );

        bytes32 messageHash = _hashTypedDataV4(keccak256(abi.encode(
                resolveDisputeHash,
                keccak256(bytes(_label)),
                _listingId,
                _orderId,
                _refundBuyer,
                5
            )));
        address recoveredAddress = ECDSA.recover(messageHash, _resolutionMessage);
        require(isJudge[recoveredAddress], "Dispute is not resolved by a judge");

        order.resolutionMessage = _resolutionMessage;

        if (_refundBuyer) {
            order.status = OrderStatus.RESOLVED_BUYER_REFUNDED;
            WORLD.transfer(order.buyer, order.total);
        } else {
            order.status = OrderStatus.RESOLVED_PAYMENT_RELEASED;
            _releasePaymentToSeller(order.seller, order.total);
        }
    }

    function setTaxRecipient(address _taxRecipient) external onlyOwner {
        taxRecipient = _taxRecipient;
    }

    function setTaxPercentage(uint256 _taxPercentage) external onlyOwner {
        require(_taxPercentage >= 1 && _taxPercentage <= 10, "Value is outside of range 1-10");
        taxPercentage = _taxPercentage;
    }
}
