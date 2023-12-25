// SPDX-License-Identifier: MIT
//
//              @@@@@@@@@@        @@@@@@@     @@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@
//            @@@@@@@@@@@@       @@@@@@@    .@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@
//          @@@@@@@@@@@@@@      @@@@@@@           @@@@@@@        @@@@@@     @@@@@@
//         @@@@@@@ @@@@@@@     @@@@@@@           @@@@@@@         @@@@@@@@@@@
//       @@@@@@@   @@@@@@@     @@@@@@            @@@@@@           @@@@@@@@@@@@@@
//      @@@@@@@@@@@@@@@@@@    @@@@@@@           @@@@@@@               #@@@@@@@@@@
//    @@@@@@@@@@@@@@@@@@@@   @@@@@@@           @@@@@@@        @@@@@@@     @@@@@@#
//   @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@ @@@@@@@         @@@@@@@@@@@@@@@@@
// @@@@@@@          @@@@@@  @@@@@@@@@@@@@@@@ @@@@@@@            @@@@@@@@@@@@

pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC1155Receiver.sol";

interface IRVM {
    function burn(address account, uint256 id, uint256 value) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);
}

interface IALTS {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract TraitSwapping is Ownable, Pausable, ReentrancyGuard, IERC1155Receiver {
    using SafeERC20 for IERC20;
    IERC20 public immutable APE;
    IRVM public immutable RVM;
    IALTS public immutable ALTS;
    IERC20 public immutable WETH;

    enum Currency {
        ETH,
        WETH,
        APE,
        RVM
    }

    enum OrderStatus {
        UNSET,
        PENDING,
        ACCEPTED,
        CANCELED
    }

    struct Order {
        address buyer;
        uint96 amount;
        address seller;
        uint32 expiresAt;
        uint24 id;
        uint16 buyerAlt;
        uint16 sellerAlt;
        OrderStatus status;
    }

    struct Transfer {
        address buyer;
        uint16[3] buyerAlts;
        uint16[3] sellerAlts;
        address seller;
        uint72 amount;
        uint24 id;
    }

    struct Exchange {
        uint72 rateApe;
        uint56 rateEth;
        uint56 minFee;
        uint56 minOrder;
        uint8 rateRvm;
        uint8 fee;
    }

    Exchange public exchange;
    address payable public receiver;
    address public permittedOperator;
    bool public pointsTransfers = false;
    uint32 public expiryPeriod;
    uint24 public totalOrders = 0;
    uint24 public totalTransfers = 0;

    mapping(address => uint256) public points;
    mapping(uint56 => Order) public orders;
    mapping(uint96 => Transfer) private transfers;

    event PointsPurchase(
        address indexed user,
        Currency indexed currency,
        uint256 value,
        uint256 indexed points,
        uint256 currentPointsBalance
    );
    event TransferPoints(address indexed sender, address indexed receiver, uint256 amount);
    event TransferWETH(uint96 indexed id, address indexed buyer, address indexed seller, uint256 amount, uint256 fee);
    event OrderCreated(
        uint56 indexed orderId,
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        uint32 expiresAt
    );
    event OrderFulfilled(uint56 indexed orderId);
    event OrderCanceled(uint56 indexed orderId, address indexed buyer, address indexed seller, uint256 amount);

    constructor(
        uint56 _rateEth,
        uint72 _rateApe,
        uint8 _rateRvm,
        uint56 _minFee,
        uint56 _minOrder,
        uint8 _fee,
        uint32 _expiryPeriod,
        address _ape,
        address _rvm,
        address _weth,
        address _alts,
        address _permittedOperator,
        address payable _receiver
    ) {
        exchange.rateEth = _rateEth;
        exchange.rateApe = _rateApe;
        exchange.rateRvm = _rateRvm;
        exchange.minFee = _minFee;
        exchange.minOrder = _minOrder;
        exchange.fee = _fee;
        expiryPeriod = _expiryPeriod;
        APE = IERC20(_ape);
        RVM = IRVM(_rvm);
        WETH = IERC20(_weth);
        ALTS = IALTS(_alts);
        permittedOperator = _permittedOperator;
        receiver = _receiver;
    }

    modifier onlyPermittedOperator() {
        require(msg.sender == permittedOperator || msg.sender == owner(), "Not a permitted operator");
        _;
    }

    /// @notice Exchanges ETH for swapping points.
    function exchangeETH() external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Amount cannot be 0");
        require(msg.value % exchange.rateEth == 0, "Invalid ETH amount");
        uint256 pointsToReceive = msg.value / exchange.rateEth;
        points[msg.sender] += pointsToReceive;
        (bool sent, ) = receiver.call{value: msg.value}("");
        require(sent, "Failed to send ETH");
        emit PointsPurchase(msg.sender, Currency.ETH, msg.value, pointsToReceive, points[msg.sender]);
    }

    /// @notice Exchanges WETH for swapping points.
    /// @param amount The amount of WETH to be exchanged.
    function exchangeWETH(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount cannot be 0");
        require(amount % exchange.rateEth == 0, "Invalid WETH amount");
        uint256 pointsToReceive = amount / exchange.rateEth;
        points[msg.sender] += pointsToReceive;
        WETH.safeTransferFrom(msg.sender, receiver, amount);
        emit PointsPurchase(msg.sender, Currency.WETH, amount, pointsToReceive, points[msg.sender]);
    }

    /// @notice Exchanges APE coin for swapping points.
    /// @param amount The amount of APE to be exchanged.
    function exchangeAPE(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount cannot be 0");
        require(amount % exchange.rateApe == 0, "Invalid APE amount");
        uint256 pointsToReceive = amount / exchange.rateApe;
        points[msg.sender] += pointsToReceive;
        APE.safeTransferFrom(msg.sender, receiver, amount);
        emit PointsPurchase(msg.sender, Currency.APE, amount, pointsToReceive, points[msg.sender]);
    }

    /// @notice Exchanges RVM coins for points.
    /// @param amount The amount of RVM coins to be exchanged.
    function exchangeRVM(uint256 amount) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount cannot be 0");
        require(amount % exchange.rateRvm == 0, "Invalid RVM amount");
        uint256 pointsToReceive = amount / exchange.rateRvm;
        points[msg.sender] += pointsToReceive;
        RVM.burn(msg.sender, 0, amount);
        emit PointsPurchase(msg.sender, Currency.RVM, amount, pointsToReceive, points[msg.sender]);
    }

    /// @notice Enables a user to create a WETH transfer.
    /// @param transfer The details of the new WETH transfer.
    function executeWETHOrder(Transfer memory transfer) external nonReentrant whenNotPaused {
        require(transfer.buyer == msg.sender, "Buyer must create own order");
        require(transfer.amount >= exchange.minOrder, "Transfer amount is below minimum");
        require(validateAltsOwnership(transfer.buyerAlts, msg.sender), "Buyer: no valid ALT ID");
        require(validateAltsOwnership(transfer.sellerAlts, transfer.seller), "Seller: no valid ALT ID");

        unchecked {
            uint256 minFee = exchange.minFee;
            uint256 calculatedFee = (transfer.amount * exchange.fee) / 100;
            uint256 feeAmount = calculatedFee < minFee ? minFee : calculatedFee;

            totalTransfers++;
            transfer.id = totalTransfers;
            transfers[transfer.id] = transfer;

            address buyer = transfer.buyer;
            WETH.safeTransferFrom(buyer, receiver, feeAmount);
            WETH.safeTransferFrom(buyer, transfer.seller, transfer.amount);

            emit TransferWETH(transfer.id, transfer.buyer, transfer.seller, transfer.amount, feeAmount);
        }
    }

    /// @notice Enables a user to create a new WETH offer.
    /// @param order The details of the new WETH offer.
    function createOrder(Order memory order) external nonReentrant whenNotPaused {
        require(order.buyer == msg.sender, "Buyer must create their own order");
        require(order.buyerAlt >= 1 && order.buyerAlt <= 30000, "Invalid buyer ALT ID");
        require(order.sellerAlt >= 1 && order.sellerAlt <= 30000, "Invalid seller ALT ID");
        require(order.amount >= exchange.minOrder, "Order amount is below minimum");

        require(ALTS.ownerOf(order.buyerAlt) == msg.sender, "Buyer does not own the specified ALT");
        require(ALTS.ownerOf(order.sellerAlt) == order.seller, "Seller does not own the specified ALT");

        // No overflow in unchecked block as order.amount is uint96 and exchange.fee is max 100
        unchecked {
            uint256 minFee = exchange.minFee;
            uint256 calculatedFee = (order.amount * exchange.fee) / 100;
            uint256 feeAmount = calculatedFee < minFee ? minFee : calculatedFee;

            require(
                WETH.allowance(msg.sender, address(this)) >= order.amount + feeAmount,
                "Insufficient WETH allowance"
            );

            totalOrders++;
        }

        order.id = totalOrders;
        order.status = OrderStatus.PENDING;
        order.expiresAt = uint32(block.timestamp + expiryPeriod);
        orders[order.id] = order;

        emit OrderCreated(order.id, order.buyer, order.seller, order.amount, order.expiresAt);
    }

    /// @notice Enables a user to cancel a WETH offer.
    /// @param id The ID of the WETH offer to be canceled.
    function cancelOrder(uint56 id) external nonReentrant whenNotPaused {
        Order storage order = orders[id];
        OrderStatus status = order.status;

        require(status != OrderStatus.UNSET, "Order does not exist");
        require(status == OrderStatus.PENDING, "Order is not pending");

        address buyer = order.buyer;

        require(
            buyer == msg.sender || permittedOperator == msg.sender || owner() == msg.sender,
            "Not the buyer of this order"
        );

        order.status = OrderStatus.CANCELED;

        emit OrderCanceled(id, buyer, order.seller, order.amount);
    }

    /// @notice Fulfills a specific WETH offer.
    /// @param id The ID of the WETH offer to be fulfilled.
    function fulfillOrder(uint56 id) external onlyPermittedOperator {
        Order storage order = orders[id];
        require(order.status == OrderStatus.PENDING, "Order not eligible for fulfillment");

        if (block.timestamp > order.expiresAt) {
            revert("Expired");
        }

        unchecked {
            uint256 orderAmount = order.amount;
            uint256 feeAmount = (orderAmount * exchange.fee) / 100;

            if (feeAmount < exchange.minFee) {
                feeAmount = exchange.minFee;
            }
            // WETH calls in unchecked block scope vs separate declarations
            address buyer = order.buyer;
            WETH.safeTransferFrom(buyer, receiver, feeAmount);
            WETH.safeTransferFrom(buyer, order.seller, orderAmount);
        }

        order.status = OrderStatus.ACCEPTED;
        emit OrderFulfilled(id);
    }

    /// @notice Enables a user to send their points to another user.
    /// @param to The address to receive the points.
    /// @param amount The amount of points to send.
    function transferPoints(address to, uint256 amount) external nonReentrant whenNotPaused {
        require(pointsTransfers, "Transfers of points are disabled");
        require(to != address(0), "Cannot send to zero address");
        require(points[msg.sender] >= amount, "Insufficient points balance");

        points[msg.sender] -= amount;
        points[to] += amount;

        emit TransferPoints(msg.sender, to, amount);
    }

    /// @notice Overwrite the current points balance for the given users.
    /// @param users The list of user addresses.
    /// @param balances The corresponding list of point balances for each user.
    function setPoints(address[] calldata users, uint256[] calldata balances) external onlyPermittedOperator {
        require(users.length == balances.length, "Mismatched arrays");
        unchecked {
            for (uint256 i = 0; i < users.length; i++) {
                points[users[i]] = balances[i];
            }
        }
    }

    /// @notice Increments or decrements the current points balance for the given users by the given amount(s).
    /// @param users The list of user addresses whose points should be incremented or decremented.
    /// @param adjustments The corresponding list of point adjustments (positive for increments, negative for decrements) for each user.
    function adjustPoints(address[] calldata users, int256[] calldata adjustments) external onlyPermittedOperator {
        require(users.length == adjustments.length, "Mismatched arrays");
        unchecked {
            for (uint256 i = 0; i < users.length; i++) {
                if (adjustments[i] > 0) {
                    points[users[i]] += uint256(adjustments[i]);
                } else {
                    require(points[users[i]] >= uint256(-adjustments[i]), "Cannot decrease below zero");
                    points[users[i]] -= uint256(-adjustments[i]);
                }
            }
        }
    }

    /// @notice Sets the wallet to receive exchange payments.
    /// @param _receiver The new address of the receiver.
    function setReceiver(address payable _receiver) external onlyOwner {
        receiver = _receiver;
    }

    /// @notice Sets the period from order creation block timestamp after which orders should expire.
    /// @param period The new expiry period in seconds (e.g. 14 days is 1209600).
    function setExpiryPeriod(uint32 period) external onlyOwner {
        expiryPeriod = period;
    }

    /// @notice Sets WETH fee and exchange rates for the supported currencies and tokens.
    /// @param eth The exchange rate for ETH.
    /// @param ape The exchange rate for APE coin.
    /// @param rvm The exchange rate for RVM coin.
    /// @param fee The fee applied to WETH offers.
    function setExchange(
        uint56 eth,
        uint72 ape,
        uint8 rvm,
        uint8 fee,
        uint56 minFee,
        uint56 minOrder
    ) external onlyOwner {
        exchange.rateApe = ape;
        exchange.rateEth = eth;
        exchange.minFee = fee;
        exchange.minOrder = minOrder;
        exchange.rateRvm = rvm;
        exchange.fee = fee;
    }

    /// @notice Sets the permitted operator address.
    /// @param _operator The address of the operator.
    function setPermittedOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Operator address cannot be null");
        permittedOperator = _operator;
    }

    /// @notice Removes permissions from the permitted operator.
    function removePermittedOperator() external onlyOwner {
        permittedOperator = address(0);
    }

    /// @notice Fetches allowances for the user for all supported tokens.
    /// @param user The address of the user.
    function getAllowances(address user) external view returns (uint256[] memory) {
        uint256[] memory allowances = new uint256[](3);
        allowances[0] = WETH.allowance(user, address(this));
        allowances[1] = APE.allowance(user, address(this));
        allowances[2] = RVM.isApprovedForAll(user, address(this)) ? 1 : 0;
        return allowances;
    }

    /// @notice Fetches orders including a specific wallet address between the given range.
    /// @param user The address of the user.
    /// @param start The starting ID of the order range.
    /// @param end The ending ID of the order range.
    /// @param isSeller Whether to fetch orders where the user is the buyer (WETH sender) or the seller (WETH receiver).
    function getOrdersByUser(
        address user,
        uint56 start,
        uint56 end,
        bool isSeller
    ) external view returns (uint56[] memory) {
        require(start <= end, "Invalid range");

        uint56[] memory orderRange = new uint56[](end - start + 1);
        uint256 count = 0;

        unchecked {
            for (uint56 i = start; i <= end; i++) {
                bool isUserOrder = (isSeller && orders[i].seller == user) || (!isSeller && orders[i].buyer == user);
                if (isUserOrder && orders[i].status != OrderStatus.UNSET) {
                    orderRange[count++] = i;
                }
            }
        }

        uint56[] memory result = new uint56[](count);
        unchecked {
            for (uint256 j = 0; j < count; j++) {
                result[j] = orderRange[j];
            }
        }
        return result;
    }

    /// @notice Gets informatiom about a WETH transfer
    /// @param transferId The ID of the transfer to get data for
    /// @dev Alternative to public transfers mapping to facilitate uint16[3] display
    function getTransfer(
        uint96 transferId
    ) public view returns (address, uint16[3] memory, uint16[3] memory, address, uint96, uint256) {
        Transfer storage t = transfers[transferId];
        return (t.buyer, t.buyerAlts, t.sellerAlts, t.seller, t.id, t.amount);
    }

    /// @notice Drains any Ether from the contract to the owner.
    /// @dev This is an emergency function for funds release.
    function drainETH() external onlyOwner {
        owner().call{value: address(this).balance}("");
    }

    /// @notice Drains any WETH from the contract to the owner.
    /// @dev This is an emergency function for funds release.
    function drainWETH() external onlyOwner {
        WETH.transfer(owner(), WETH.balanceOf(address(this)));
    }

    /// @notice Drains any APE tokens from the contract to the owner.
    /// @dev This is an emergency function for funds release.
    function drainAPE() external onlyOwner {
        APE.transfer(owner(), APE.balanceOf(address(this)));
    }

    /// @notice Enables peer-to-peer points transfer.
    function enableTransfers() external onlyOwner {
        pointsTransfers = true;
    }

    /// @notice Disables peer-to-peer points transfer.
    function disableTransfers() external onlyOwner {
        pointsTransfers = false;
    }

    /// @notice Pauses exchanges and points issuance.
    function pause() external onlyPermittedOperator {
        _pause();
    }

    /// @notice Unpauses exchanges and points issuance.
    function unpause() external onlyPermittedOperator {
        _unpause();
    }

    /// @dev Issues swapping points for RVM coins send to the contract.
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(address(RVM) == msg.sender, "Only RVM tokens accepted");
        require(id == 0, "Only RVM tokenId 0 accepted");

        uint256 pointsToReceive = value / exchange.rateRvm;
        points[from] += pointsToReceive;

        emit PointsPurchase(from, Currency.RVM, value, pointsToReceive, points[from]);

        RVM.burn(address(this), id, value);

        return this.onERC1155Received.selector;
    }

    /// @dev Declines batch transfers of ERC1155 tokens to the contract.
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        revert("Not supported");
    }

    /// @dev Supports IERC1155Receiver
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    /// @notice Check a wallet owns the given ALTs
    /// @param tokenIds The ALT tokenIds to check
    /// @param owner The expected owner wallet address
    function validateAltsOwnership(uint16[3] memory tokenIds, address owner) internal view returns (bool) {
        bool validAlt = false;
        for (uint i = 0; i < 3; i++) {
            if (tokenIds[i] != 0) {
                validAlt = true;
                require(ALTS.ownerOf(tokenIds[i]) == owner, "ALT ownership mismatch");
            }
        }
        return validAlt;
    }
}
