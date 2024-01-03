// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./IOrderFulfiller.sol";
import "./IERC1155.sol";
import "./IHotpot.sol";
import "./IMarketplace.sol";

contract Marketplace is 
    IMarketplace, 
    IOrderFulfiller, 
    ReentrancyGuardUpgradeable, 
    OwnableUpgradeable,
    EIP712Upgradeable
{
    /* 
        Hotpot variables
     */
    address public raffleContract; 
    uint16 public raffleTradeFee;
    address public operator;

    // Status
    mapping(bytes32 => OrderStatus) public orderStatus; // order hash => OrderStatus

    /* 
        EIP712
     */
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 constant OFFER_ITEM_TYPEHASH = keccak256(
        "OfferItem(address offerToken,uint256 offerTokenId,uint256 offerAmount,uint256 endTime,uint256 amount)"
    ); 
    bytes32 constant ROYALTY_DATA_TYPEHASH = keccak256(
        "RoyaltyData(uint256 royaltyPercent,address royaltyRecipient)"
    ); 
    // Order typehash - this is a structured data, that user signs when listing
    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address offerer,OfferItem offerItem,RoyaltyData royalty,uint256 salt)OfferItem(address offerToken,uint256 offerTokenId,uint256 offerAmount,uint256 endTime,uint256 amount)RoyaltyData(uint256 royaltyPercent,address royaltyRecipient)"
    );

    /* 
        Constants
     */
    uint256 constant HUNDRED_PERCENT = 10000;

    constructor() {
        _disableInitializers();
    }

    function initialize(uint16 _raffleTradeFee, address _operator)
        external 
        initializer
    {
        __ReentrancyGuard_init();
        __Ownable_init();
        __EIP712_init("Hotpot", "0.1.0");
        raffleTradeFee = _raffleTradeFee;
        operator = _operator;
        DOMAIN_SEPARATOR = _domainSeparatorV4();
    }

    function fulfillOrder(OrderParameters memory parameters)
        external 
        payable
        nonReentrant 
    {
        address receiver = parameters.receiver == address(0) ? 
                msg.sender : parameters.receiver;
        OfferItem memory offerItem = parameters.offerItem;
        RoyaltyData memory royalty = parameters.royalty;
        uint256 tradeAmount = _calculateTradeAmount(
            offerItem.offerAmount, 
            royalty.royaltyPercent
        );
        uint256 hotpotFeeAmount = _getHotpotFeeAmount(tradeAmount);
        uint256 royaltyAmount = _getRoyaltyAmount(
            tradeAmount, royalty.royaltyPercent
        );
        require(msg.value >= tradeAmount, "Insufficient ether provided");

        // validating and fulfilling the order
        _fulfillOrder(parameters, royaltyAmount, tradeAmount);

        /* 
            Execute Hotpot trade to generate tickets
         */
        address _raffleContract = raffleContract;
        if (_raffleContract != address(0)) {
            IHotpot(_raffleContract).executeTrade{ value: hotpotFeeAmount }(
                tradeAmount,
                receiver,
                parameters.offerer
            );
        }
    }

    function batchFulfillOrder(
        OrderParameters[] memory parameters
    )
        external payable nonReentrant
    {
        uint256 orders_n = parameters.length;
        
        /* 
            Fulfilling orders
         */
        uint256 tradeAmountTotal = 0;
        uint256 raffleFeeTotal = 0;
        IHotpot.BatchTradeParams[] memory batchTradeParams = 
            new IHotpot.BatchTradeParams[](orders_n);

        for(uint256 i = 0; i < orders_n; i++) {
            OrderParameters memory order = parameters[i];
            OfferItem memory offerItem = order.offerItem;
            RoyaltyData memory royalty = order.royalty;

            uint256 tradeAmount = _calculateTradeAmount(
                offerItem.offerAmount,
                royalty.royaltyPercent
            );
            uint256 hotpotFeeAmount = _getHotpotFeeAmount(tradeAmount);
            uint256 royaltyAmount = _getRoyaltyAmount(
                tradeAmount, royalty.royaltyPercent
            );
            tradeAmountTotal += tradeAmount;
            raffleFeeTotal += hotpotFeeAmount;

            // Preparing parameters for executeTrade
            batchTradeParams[i] = _convertToBatchTradeParams(
                parameters[i],
                tradeAmount
            );

            // validating and fulfilling the order
            _fulfillOrder(order, royaltyAmount, tradeAmount);
        }

        require(msg.value >= tradeAmountTotal, "Insufficient ether provided");

        /* 
            Execute batch trade
         */
        address _raffleContract = raffleContract;
        if (_raffleContract != address(0)) {
            IHotpot(_raffleContract).batchExecuteTrade{ value: raffleFeeTotal }(
                batchTradeParams
            );
        }
    }

    function cancelOrder(PureOrder memory order)
        external
    {
        require(msg.sender == order.offerer, "Caller must be orderer");
        /* 
            Obtain order hash and validate status
         */
        bytes32 _hash = _calculatePureOrderTypedHash(order);
        OrderStatus storage _orderStatus = orderStatus[_hash];
        require(!_orderStatus.isCancelled, "Order is already cancelled");
        require(!_orderStatus.isFulfilled, "Cannot cancel fulfilled order");
        _orderStatus.isCancelled = true;
        emit OrderCancelled(
            order.offerer,
            order.offerItem.offerToken,
            order.offerItem.offerTokenId,
            _hash
        );
    }

    function setRaffleAddress(address _raffleAddress) external onlyOwner {
        require(raffleContract == address(0), 
            "Raffle contract can only be set once");
        address marketplace = IHotpot(_raffleAddress).marketplace();
        require(marketplace == address(this), "Invalid raffle contract");
        raffleContract = _raffleAddress;
        emit RaffleAddressSet(_raffleAddress);
    }

    function setRaffleTradeFee(uint16 _newTradeFee) external onlyOwner {
        require(_newTradeFee <= HUNDRED_PERCENT, "Inadequate marketplace fee");
        raffleTradeFee = _newTradeFee;
        IHotpot(raffleContract).setTradeFee(_newTradeFee);
        emit RaffleTradeFeeChanged(_newTradeFee);
    }

    function setOperator(address _newOperator) external onlyOwner {
        require(_newOperator != operator, "Operator didnt change");
        operator = _newOperator;
        IHotpot(raffleContract).setOperator(_newOperator);
        emit OperatorChanged(_newOperator);
    }

    /* 

        ***
        INTERNAL
        ***
    
     */
    function _fulfillOrder(
        OrderParameters memory parameters,
        uint256 royaltyAmount,
        uint256 tradeAmount
    ) internal {
        address receiver = parameters.receiver == address(0) ? 
            msg.sender : parameters.receiver;
        OfferItem memory offerItem = parameters.offerItem;
        RoyaltyData memory royalty = parameters.royalty;
        address payable offerer = parameters.offerer;

        require(block.timestamp <= parameters.offerItem.endTime, 
            "Offer has expired");

        /* 
            Calculating EIP712 hash of the order data and validating it
            agains the specified signature
         */
        bytes32 _orderHash = _validateOrderData(parameters);

        // Validate and update order status
        OrderStatus storage _orderStatus = orderStatus[_orderHash];
        _validateOrderStatus(_orderStatus);
        _orderStatus.isFulfilled = true;

        /* 
            Transfer ether to all recepients
            and the NFT to the caller
         */
        {
            // Transfer native currency to the offerer
            offerer.transfer(offerItem.offerAmount);
            
            // Transfer NFT to the caller
            if (parameters.tokenType == OfferTokenType.ERC721) {
                IERC721(offerItem.offerToken).safeTransferFrom(
                    offerer, receiver, offerItem.offerTokenId
                );
            }
            // Individual ERC1155 transfer
            else {
                bytes memory data = "";
                IERC1155(offerItem.offerToken).safeTransferFrom(
                    offerer, receiver, offerItem.offerTokenId, offerItem.amount, data
                );
            }
            
            // Transfer royalty
            if (royalty.royaltyRecipient != address(0) && royaltyAmount > 0) {
                royalty.royaltyRecipient.transfer(royaltyAmount);
            }
        }

        emit OrderFulfilled(
            offerer,
            receiver,
            offerItem.offerToken,
            offerItem.offerTokenId,
            offerItem.amount,
            tradeAmount,
            _orderHash
        );
    }

    function _validateOrderData(OrderParameters memory parameters) 
        internal
        view
        returns(bytes32 orderHash)
    {
        address receiver = parameters.receiver == address(0) ? 
            msg.sender : parameters.receiver;

        orderHash = _hashTypedDataV4(_calculateOrderHashStruct(parameters));
        address orderSigner = ECDSAUpgradeable.recover(orderHash, parameters.orderSignature);
        // validate signer
        require(orderSigner == parameters.offerer, "Offerer address must be the signer");
        require(msg.sender != parameters.offerer, "Signer cannot fulfill their own order");
        require(receiver != parameters.offerer, "Offerer cannot be receiver");
        require(parameters.tokenType == OfferTokenType.ERC721 || 
            parameters.tokenType == OfferTokenType.ERC1155, 
            "Unsupported offer token type"
        );
        if (parameters.tokenType == OfferTokenType.ERC721) {
            require(parameters.offerItem.amount == 1, "Invalid token amount");
        }
        else {
            require(parameters.offerItem.amount > 0, "Invalid token amount");
        }
    }

    function _calculateOrderHashStruct(OrderParameters memory parameters) 
        internal 
        pure
        returns(bytes32 _orderHash) 
    {
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            parameters.offerer,
            _calculateOfferItemHashStruct(parameters.offerItem),
            _calculateRoyaltyDataHashStruct(parameters.royalty),
            parameters.salt
        ));
    }

    function _calculatePureOrderTypedHash(PureOrder memory order) 
        internal 
        view
        returns(bytes32 _orderHash) 
    {
        bytes32 hashStruct = keccak256(abi.encode(
            ORDER_TYPEHASH,
            order.offerer,
            _calculateOfferItemHashStruct(order.offerItem),
            _calculateRoyaltyDataHashStruct(order.royalty),
            order.salt
        ));
        _orderHash = _hashTypedDataV4(hashStruct);
    }

    function _calculateOfferItemHashStruct(OfferItem memory offerItem) 
        internal
        pure
        returns(bytes32 _offerItemHash)
    {
        return keccak256(abi.encode(
            OFFER_ITEM_TYPEHASH,
            offerItem.offerToken,
            offerItem.offerTokenId,
            offerItem.offerAmount,
            offerItem.endTime,
            offerItem.amount
        ));
    }

    function _calculateRoyaltyDataHashStruct(RoyaltyData memory royaltyData) 
        internal
        pure
        returns(bytes32 _royaltyHash) 
    {
        return keccak256(abi.encode(
            ROYALTY_DATA_TYPEHASH,
            royaltyData.royaltyPercent,
            royaltyData.royaltyRecipient
        ));
    }

    function _validateOrderStatus(OrderStatus storage _orderStatus) 
        internal
        view
    {
        require(!_orderStatus.isCancelled, 
            "Order is cancelled and cannot be fulfilled");
        require(!_orderStatus.isFulfilled, "Order is already fulfilled");
    }

    function _calculateTradeAmount(
        uint256 offerAmount,
        uint256 royaltyPercent
    ) internal view returns(uint256) {
        return offerAmount * HUNDRED_PERCENT
         / (HUNDRED_PERCENT - raffleTradeFee - royaltyPercent);
    }

    function _getHotpotFeeAmount(
        uint256 tradeAmount
    ) internal view returns(uint256) {
        return tradeAmount * raffleTradeFee / HUNDRED_PERCENT;
    }

    function _getRoyaltyAmount(
        uint256 tradeAmount,
        uint256 royaltyPercent
    ) internal pure returns(uint256) {
        return tradeAmount * royaltyPercent / HUNDRED_PERCENT;
    }

    function _convertToBatchTradeParams(
        OrderParameters memory order,
        uint256 tradeAmount
    ) internal view returns (IHotpot.BatchTradeParams memory params) {
        address receiver = order.receiver == address(0) ? 
            msg.sender : order.receiver;

        params = IHotpot.BatchTradeParams({
            _amountInWei: tradeAmount,
            offerer: order.offerer,
            receiver: receiver
        });
    }
}