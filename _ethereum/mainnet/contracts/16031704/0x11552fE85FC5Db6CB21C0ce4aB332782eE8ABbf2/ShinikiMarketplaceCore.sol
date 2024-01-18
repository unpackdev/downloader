// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./LibFill.sol";
import "./LibTransfer.sol";
import "./OrderValidator.sol";
import "./AssetMatcher.sol";
import "./TransferManager.sol";
import "./IShinikiMarketplaceCore.sol";

abstract contract ShinikiMarketplaceCore is
    Initializable,
    AssetMatcher,
    OrderValidator,
    TransferManager,
    IShinikiMarketplaceCore,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using LibTransfer for address;

    mapping(address => bool) public isOperators;

    uint256 private constant UINT256_MAX = 2**256 - 1;

    address public TRUSTED_PARTY;

    //state of the orders
    mapping(bytes32 => uint256) public fills;

    function _decodeOrderData(bytes calldata data)
        internal
        pure
        returns (LibOrderData.Data memory orderData)
    {
        orderData = abi.decode(data, (LibOrderData.Data));
    }

    function _parse(LibOrder.Order calldata order)
        internal
        pure
        returns (LibOrderData.Data memory dataOrder)
    {
        if (
            order.dataType == LibOrderData.V1 ||
            order.dataType == LibOrderData.V2
        ) {
            dataOrder = _decodeOrderData(order.data);
        } else if (order.dataType == 0xffffffff) {} else {
            revert("Unknown Order data type");
        }
        dataOrder.recipient = payable(order.maker);
    }

    function cancel(LibOrder.Order calldata order)
        external
        override
        nonReentrant
        whenNotPaused
    {
        require(order.maker != address(0), "address is not zero");
        require(_msgSender() == order.maker, "not a maker");
        require(order.salt != 0, "0 salt can't be used");
        bytes32 orderKeyHash = LibOrder._hashKey(order);
        require(fills[orderKeyHash] != UINT256_MAX, "already canceled");
        fills[orderKeyHash] = UINT256_MAX;
        bytes4 typeOrder = bytes4(keccak256("SELL_ORDER"));
        if (
            order.makeAsset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS ||
            order.makeAsset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS
        ) {
            typeOrder = bytes4(keccak256("OFFER"));
        }
        emit Cancel(order.salt, typeOrder, orderKeyHash);
    }

    /**
        @notice verify signature and match orders 
        @param orderLeft the left order of the match
        @param signatureLeft the signature of left order
        @param orderRight the right order of the match
        @param signatureRight the signature of right order
     */
    function matchOrders(
        LibOrder.Order calldata orderLeft,
        bytes calldata signatureLeft,
        LibOrder.Order calldata orderRight,
        bytes calldata signatureRight
    ) external payable override nonReentrant whenNotPaused {
        require(
            orderLeft.dataType == bytes4(keccak256("V1")),
            "Invalid match order"
        );
        _validateFull(orderLeft, signatureLeft);
        _validateFull(orderRight, signatureRight);
        if (orderLeft.taker != address(0)) {
            require(
                orderRight.maker == orderLeft.taker,
                "BuyNow/Offer: leftOrder.taker verification failed"
            );
        }
        if (orderRight.taker != address(0)) {
            require(
                orderRight.taker == orderLeft.maker,
                "BuyNow/Offer: rightOrder.taker verification failed"
            );
        }
        _matchAndTransfer(orderLeft, orderRight, signatureRight);

        if (address(this).balance > 0) {
            address(msg.sender)._transferEth(address(this).balance);
        }
    }

    /**
        @notice verify signature and match batch orders 
        @param batchOrder the left order of the match
     */
    function matchBatchOrders(LibOrder.BatchOrder[] calldata batchOrder)
        external
        payable
        override
        nonReentrant
        whenNotPaused
    {
        unchecked {
            for (uint256 i = 0; i < batchOrder.length; i++) {
                _validateFull(
                    batchOrder[i].orderLeft,
                    batchOrder[i].signatureLeft
                );
                if (batchOrder[i].orderLeft.taker != address(0)) {
                    require(
                        batchOrder[i].orderRight.maker ==
                            batchOrder[i].orderLeft.taker,
                        "Buybulk: leftOrder.taker verification failed"
                    );
                }
                if (batchOrder[i].orderRight.taker != address(0)) {
                    require(
                        batchOrder[i].orderRight.taker ==
                            batchOrder[i].orderLeft.maker,
                        "Buybulk: rightOrder.taker verification failed"
                    );
                }
                _matchAndTransfer(
                    batchOrder[i].orderLeft,
                    batchOrder[i].orderRight,
                    "0x"
                );
            }
        }
        if (address(this).balance > 0) {
            address(msg.sender)._transferEth(address(this).balance);
        }
    }

    /**
        @notice verify signature and match auction orders 
        @param orderLeft the left order of the match
        @param signatureLeft the signature of left order
        @param orderRight the right order of the match
        @param signatureRight the signature of right order
     */
    function auctionOrder(
        LibOrder.Order calldata orderLeft,
        bytes calldata signatureLeft,
        LibOrder.Order calldata orderRight,
        bytes calldata signatureRight
    ) external override nonReentrant whenNotPaused {
        require(
            msg.sender == TRUSTED_PARTY || msg.sender == orderLeft.maker,
            "Not Trusted party nor the owner"
        );
        require(
            orderLeft.dataType == bytes4(keccak256("V2")),
            "Invalid Auction order"
        );

        _validateFull(orderLeft, signatureLeft);
        _validateFull(orderRight, signatureRight);
        if (orderRight.taker != address(0)) {
            require(
                orderLeft.maker == orderRight.taker,
                "Auction: rightOrder.taker verification failed"
            );
        }

        _matchAndTransferAuctionOrder(orderLeft, orderRight);

        if (address(this).balance > 0) {
            address(msg.sender)._transferEth(address(this).balance);
        }
    }

    /**
        @notice matches valid orders and transfers their assets
        @param orderLeft the left order of the match
        @param orderRight the right order of the match
    */
    function _matchAndTransfer(
        LibOrder.Order calldata orderLeft,
        LibOrder.Order calldata orderRight,
        bytes memory signatureRight
    ) internal {
        (
            LibAsset.AssetType memory makeMatch,
            LibAsset.AssetType memory takeMatch
        ) = _matchAssets(orderLeft, orderRight);

        LibOrderData.Data memory leftOrderData = _parse(orderLeft);
        LibOrderData.Data memory rightOrderData = _parse(orderRight);

        LibFill.FillResult memory newFill = _getFillSetNew(
            orderLeft,
            orderRight,
            leftOrderData.isMakeFill,
            rightOrderData.isMakeFill
        );

        _doTransfers(
            makeMatch,
            takeMatch,
            newFill,
            orderLeft,
            orderRight,
            leftOrderData,
            rightOrderData
        );

        if (signatureRight.length != 65) {
            emit Match(
                msg.sender,
                orderLeft.salt,
                bytes4(keccak256("BUY_NOW")),
                newFill.rightValue,
                newFill.leftValue
            );
        } else {
            emit Match(
                msg.sender,
                orderRight.salt,
                bytes4(keccak256("ACCEPT_OFFER")),
                newFill.rightValue,
                newFill.leftValue
            );
        }
    }

    function _matchAndTransferAuctionOrder(
        LibOrder.Order calldata orderLeft,
        LibOrder.Order calldata orderRight
    ) internal {
        LibAsset.AssetType memory makeMatch = _matchAssets(
            orderLeft.makeAsset.assetType,
            orderRight.takeAsset.assetType,
            orderLeft
        );

        LibAsset.AssetType memory takeMatch = _matchAssets(
            orderLeft.takeAsset.assetType,
            orderRight.makeAsset.assetType,
            orderLeft
        );

        LibOrderData.Data memory leftOrderData = _parse(orderLeft);
        LibOrderData.Data memory rightOrderData = _parse(orderRight);

        LibFill.FillResult memory newFill = _getFillSetNew(
            orderLeft,
            orderRight,
            leftOrderData.isMakeFill,
            rightOrderData.isMakeFill
        );

        _doTransfers(
            makeMatch,
            takeMatch,
            newFill,
            orderLeft,
            orderRight,
            leftOrderData,
            rightOrderData
        );
        emit MatchAuction(
            orderLeft.maker,
            orderLeft.salt,
            orderRight.salt,
            newFill.leftValue,
            newFill.rightValue
        );
    }

    /**
        @notice calculates fills for the matched orders and set them in "fills" mapping
        @param orderLeft left order of the match
        @param orderRight right order of the match
        @param leftMakeFill true if the left orders uses make-side fills, false otherwise
        @param rightMakeFill true if the right orders uses make-side fills, false otherwise
        @return returns change in orders' fills by the match 
    */
    function _getFillSetNew(
        LibOrder.Order calldata orderLeft,
        LibOrder.Order calldata orderRight,
        bool leftMakeFill,
        bool rightMakeFill
    ) internal returns (LibFill.FillResult memory) {
        bytes32 leftOrderKeyHash = LibOrder._hashKey(orderLeft);
        bytes32 rightOrderKeyHash = LibOrder._hashKey(orderRight);
        uint256 leftOrderFill = _getOrderFill(orderLeft.salt, leftOrderKeyHash);
        uint256 rightOrderFill = _getOrderFill(
            orderRight.salt,
            rightOrderKeyHash
        );
        LibFill.FillResult memory newFill;
        if (msg.sender != TRUSTED_PARTY) {
            newFill = LibFill._fillOrder(
                orderLeft,
                orderRight,
                leftOrderFill,
                rightOrderFill,
                leftMakeFill,
                rightMakeFill
            );
        } else {
            newFill = LibFill._fillAuctionOrder(
                orderLeft,
                orderRight,
                leftOrderFill,
                rightOrderFill,
                leftMakeFill,
                rightMakeFill
            );
        }

        require(
            newFill.rightValue > 0 && newFill.leftValue > 0,
            "nothing to fill"
        );

        if (orderLeft.salt != 0) {
            if (leftMakeFill) {
                fills[leftOrderKeyHash] = leftOrderFill.add(newFill.leftValue);
            } else {
                fills[leftOrderKeyHash] = leftOrderFill.add(newFill.rightValue);
            }
        }

        if (orderRight.salt != 0) {
            if (rightMakeFill) {
                fills[rightOrderKeyHash] = rightOrderFill.add(
                    newFill.rightValue
                );
            } else {
                fills[rightOrderKeyHash] = rightOrderFill.add(
                    newFill.leftValue
                );
            }
        }
        return newFill;
    }

    function _getOrderFill(uint256 salt, bytes32 hash)
        internal
        view
        returns (uint256 fill)
    {
        if (salt != 0) {
            fill = fills[hash];
        } else {
            fill = 0;
        }
    }

    function _matchAssets(
        LibOrder.Order calldata orderLeft,
        LibOrder.Order calldata orderRight
    )
        internal
        view
        returns (
            LibAsset.AssetType memory makeMatch,
            LibAsset.AssetType memory takeMatch
        )
    {
        makeMatch = _matchAssets(
            orderLeft.makeAsset.assetType,
            orderRight.takeAsset.assetType,
            orderLeft
        );
        require(makeMatch.assetClass != 0, "assets don't match");
        takeMatch = _matchAssets(
            orderLeft.takeAsset.assetType,
            orderRight.makeAsset.assetType,
            orderLeft
        );
        require(takeMatch.assetClass != 0, "assets don't match");
    }

    function _validateFull(
        LibOrder.Order calldata order,
        bytes calldata signature
    ) internal view {
        LibOrder._verifyTime(order);
        _verifySignature(order, signature);
    }

    modifier onlyOperator() {
        require(isOperators[msg.sender], "caller not operator");
        _;
    }

    // set address operator
    function setOperator(address _operator, bool _status)
        external
        onlyOperator
    {
        isOperators[_operator] = _status;
    }

    // set address accept auction
    function setTrustedParty(address _trusted) external onlyOperator {
        TRUSTED_PARTY = _trusted;
    }

    /**
    @dev Pause the contract
     */
    function pause() public onlyOperator {
        _pause();
    }

    /**
    @dev Unpause the contract
     */
    function unpause() public onlyOperator {
        _unpause();
    }

    receive() external payable {}
}
