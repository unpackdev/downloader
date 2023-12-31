// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC721.sol";

import "./Sendable.sol";

import "./IEndstateNFTWrapper.sol";
import "./IEscrow.sol";
import "./IOrderBook.sol";

contract OrderBook is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    Sendable,
    IOrderBook
{
    // tokenId -> Order info
    mapping(uint256 => Order) public orders;

    uint256 public override orderCount;

    uint256 public constant MIN_LIST_PRICE = 0.05 ether;

    uint256 public constant LIST_DURATION_BUTTER = 1 days;

    // EndState NFT Contract
    IEndstateNFTWrapper wrapper;
    IEscrow escrow;

    // OrderBook events
    event Debug(address sender, address endstateOperations);

    // Endstate operations address to whitelist
    address public endstateOperations;

    // common check modifier
    modifier onlyNFTOwnerOrAdmin(address dropAddress, uint256 tokenId) {
        // does it belong to a particular drop?
        require(
            wrapper.isValidNFT(dropAddress, tokenId),
            "OB: invalid drop address"
        );
        // is the caller the owner of the NFT?
        require(
            (IERC721(dropAddress).ownerOf(tokenId) == msg.sender ||
                msg.sender == endstateOperations),
            "OB: invalid owner"
        );
        _;
    }

    modifier validOrder(uint256 orderId) {
        require(orderId < orderCount, "OB: invalid order id");
        _;
    }

    function initialize(
        IEndstateNFTWrapper _wrapper,
        IEscrow _escrow,
        address _endstateOperations
    ) external initializer {
        __Ownable_init_unchained();

        wrapper = _wrapper;
        escrow = _escrow;
        endstateOperations = _endstateOperations;
    }

    function approveEscrow(address drop, uint256 tokenId) external {
        IERC721 drop_ = IERC721(drop);
        drop_.approve(address(escrow), tokenId);
    }

    /// @param drop drop address
    /// @param tokenId token id
    /// @param price price in native currency (wei)
    /// @param quality ebay based quality value
    /// @param expiry expiration date in UTC
    function list(
        address drop,
        uint256 tokenId,
        uint256 price,
        Quality quality,
        uint256 expiry
    ) external onlyNFTOwnerOrAdmin(drop, tokenId) {
        require(price >= MIN_LIST_PRICE, "OB: listing price too low");
        require(
            expiry >= block.timestamp + LIST_DURATION_BUTTER,
            "OB: invalid expiry"
        );
        IERC721 drop_ = IERC721(drop);

        require(
            drop_.getApproved(tokenId) == address(escrow),
            "OB: not approved for escrow"
        );

        escrow.lock(drop, tokenId, msg.sender);

        orders[orderCount] = Order(
            msg.sender,
            address(0),
            drop,
            tokenId,
            quality,
            price,
            Method.Crypto,
            Status.Open,
            expiry
        );

        orderCount++;

        emit OrderCreated(orderCount - 1, msg.sender, drop, tokenId, price);
    }

    /// @param drop drop address
    /// @param tokenId token id
    /// @param price price in native currency (wei)
    /// @param quality ebay based quality value
    /// @param expiry expiration date in UTC
    /// @param tokenOwner address of owner who owns NFT
    function listv2(
        address drop,
        uint256 tokenId,
        uint256 price,
        Quality quality,
        uint256 expiry,
        address tokenOwner
    ) external returns (uint256) {
        require(price >= MIN_LIST_PRICE, "OB: listing price too low");
        require(
            expiry >= block.timestamp + LIST_DURATION_BUTTER,
            "OB: invalid expiry"
        );
        IERC721 drop_ = IERC721(drop);

        require(
            drop_.getApproved(tokenId) == address(escrow),
            "OB: not approved for escrow"
        );

        escrow.lock(drop, tokenId, tokenOwner);

        orders[orderCount] = Order(
            tokenOwner,
            address(0),
            drop,
            tokenId,
            quality,
            price,
            Method.Crypto,
            Status.Open,
            expiry
        );

        orderCount++;

        emit OrderCreated(orderCount - 1, msg.sender, drop, tokenId, price);
        return orderCount - 1;
    }

    function delist(uint256 orderId) external override validOrder(orderId) {
        Order memory order = orders[orderId];

        require(order.status == Status.Open, "OB: order is not open");
        require(order.from == msg.sender, "OB: not order owner");

        escrow.releaseNFT(msg.sender, order.drop, order.tokenId);

        order.status = Status.Cancelled;
        orders[orderId] = order;

        emit OrderCancelled(orderId, CancelReason.Delist);
    }

    function buy(
        uint256 orderId
    ) external payable override validOrder(orderId) {
        Order memory order = orders[orderId];

        require(order.status == Status.Open, "OB: order is not open");
        require(msg.value >= order.price, "OB: price too low");
        require(block.timestamp <= order.expiry, "OB: listing expired");

        uint256 remainingEth = msg.value - order.price;
        // TODO: UNCOMMENT
        //if (remainingEth > 0) {
        //    sendEth(payable(msg.sender), remainingEth);
        //}

        sendEth(payable(address(escrow)), order.price);

        order.status = Status.Pending;
        order.to = msg.sender;
        orders[orderId] = order;

        emit OrderPurchased(orderId, Status.Pending);
    }

    function buyv2(
        uint256 orderId,
        address buyer
    ) public payable override validOrder(orderId) {
        Order memory order = orders[orderId];

        require(order.status == Status.Open, "OB: order is not open");
        require(msg.value >= order.price, "OB: price too low");
        require(block.timestamp <= order.expiry, "OB: listing expired");

        uint256 remainingEth = msg.value - order.price;
        if (remainingEth > 0) {
            //this assumes the `buyer` is the one who initiated the transaction
            sendEth(payable(buyer), remainingEth);
        }

        sendEth(payable(address(escrow)), order.price);

        order.status = Status.Pending;
        order.to = buyer;
        orders[orderId] = order;

        emit OrderPurchased(orderId, Status.Pending);
    }

    function buyList(
        address drop,
        uint256 tokenId,
        uint256 price,
        Quality quality,
        uint256 expiry,
        address tokenOwner,
        address buyer
    ) external payable {
        uint256 orderId = this.listv2(
            drop,
            tokenId,
            price,
            quality,
            expiry,
            tokenOwner
        );
        this.buyv2{value: msg.value}(orderId, buyer);
    }

    function fulfill(uint256 orderId) external override validOrder(orderId) {
        Order memory order = orders[orderId];

        require(order.status == Status.Pending, "OB: order is not pending");
        emit Debug(msg.sender, endstateOperations);
        require(
            order.to == msg.sender || msg.sender == endstateOperations,
            "OB: order is not yours"
        );

        escrow.releaseNFT(order.to, order.drop, order.tokenId);
        escrow.releaseFund(order.from, order.price);

        order.status = Status.Fulfilled;
        orders[orderId] = order;

        emit OrderFullfilled(orderId);
    }

    function dispute(uint256 orderId) external override validOrder(orderId) {
        Order memory order = orders[orderId];

        require(
            order.from == msg.sender || order.to == msg.sender,
            "OB: invalid caller"
        );
        require(order.status == Status.Pending, "OB: invalid status");

        order.status = Status.Dispute;
        orders[orderId] = order;

        emit OrderCancelled(orderId, CancelReason.Dispute);
    }

    function resolveDispute(
        uint256 orderId
    ) external validOrder(orderId) onlyOwner {
        Order memory order = orders[orderId];

        require(order.status == Status.Dispute, "OB: invalid status");

        escrow.releaseNFT(order.to, order.drop, order.tokenId);
        escrow.releaseFund(order.from, order.price);

        order.status = Status.Fulfilled;
        orders[orderId] = order;

        emit OrderFullfilled(orderId);
    }

    function getOrder(
        uint256 orderId
    ) external view override validOrder(orderId) returns (Order memory) {
        Order memory _order = orders[orderId];
        return _order;
    }

    function getOpenOrders() external view returns (Order[] memory) {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
