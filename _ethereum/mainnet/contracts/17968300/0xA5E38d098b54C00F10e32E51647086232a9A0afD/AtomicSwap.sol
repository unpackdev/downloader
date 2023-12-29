// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeERC20.sol";

/**
 * @author  Catalog
 * @title   HTLC smart contract for atomic swaps
 * @notice  Any signer can create an order to serve as one of either halfs of an cross chain
 *          atomic swap.
 * @dev     The contracts can be used to create an order to serve as the the commitment for two
 *          types of users :
 *          Initiator functions: 1. initate
 *                               2. refund
 *          Redeemer funtions: 1. redeem
 */

contract AtomicSwap {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;

    struct Order {
        address redeemer;
        address initiator;
        uint256 expiry;
        uint256 initiatedAt;
        uint256 amount;
        bool isFulfilled;
    }
    mapping(bytes32 => Order) public atomicSwapOrders;

    event Redeemed(
        bytes32 indexed orderId,
        bytes32 indexed secrectHash,
        bytes secret
    );
    event Initiated(
        bytes32 indexed orderId,
        bytes32 indexed secretHash,
        uint256 initiatedAt,
        uint256 amount
    );
    event Refunded(bytes32 indexed orderId);

    /**
     * @notice  .
     * @dev     provides checks to ensure
     *              1. redeemer is not null address
     *              2. redeemer is not same as the refunder
     *              3. expiry is greater than current block number
     *              4. amount is not zero
     * @param   redeemer  public address of the reedeem
     * @param   intiator  public address of the initator
     * @param   expiry  expiry in period for the htlc order
     * @param   amount  amount of tokens to trade
     */
    modifier checkSafe(
        address redeemer,
        address intiator,
        uint256 expiry,
        uint256 amount
    ) {
        require(redeemer != address(0), "AtomicSwap: invalid redeemer address");
        require(
            intiator != redeemer,
            "AtomicSwap: redeemer and initiator cannot be the same"
        );
        require(expiry > 0, "AtomicSwap: expiry should be greater than zero");
        require(amount > 0, "AtomicSwap: amount cannot be zero");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
     * @notice  Signers can create an order with order params
     * @dev     Secret used to generate secret hash for iniatiation should be generated randomly
     *          and sha256 hash should be used to support hashing methods on other non-evm chains.
     *          Signers cannot generate orders with same secret hash or override an existing order.
     * @param   _redeemer  public address of the redeemer
     * @param   _expiry  expiry in period for the htlc order
     * @param   _amount  amount of tokens to trade
     * @param   _secretHash  sha256 hash of the secret used for redemtion
     */
    function initiate(
        address _redeemer,
        uint256 _expiry,
        uint256 _amount,
        bytes32 _secretHash
    ) external checkSafe(_redeemer, msg.sender, _expiry, _amount) {
        bytes32 OrderId = sha256(abi.encode(_secretHash, msg.sender));
        Order memory order = atomicSwapOrders[OrderId];
        require(order.redeemer == address(0x0), "AtomicSwap: duplicate order");
        Order memory newOrder = Order({
            redeemer: _redeemer,
            initiator: msg.sender,
            expiry: _expiry,
            initiatedAt: block.number,
            amount: _amount,
            isFulfilled: false
        });
        atomicSwapOrders[OrderId] = newOrder;
        emit Initiated(
            OrderId,
            _secretHash,
            newOrder.initiatedAt,
            newOrder.amount
        );
        token.safeTransferFrom(msg.sender, address(this), newOrder.amount);
    }

    /**
     * @notice  Signers with correct secret to an order's secret hash can redeem to claim the locked
     *          token
     * @dev     Signers are not allowed to redeem an order with wrong secret or redeem the same order
     *          multiple times
     * @param   _orderId  orderIds if the htlc order
     * @param   _secret  secret used to redeem an order
     */
    function redeem(bytes32 _orderId, bytes calldata _secret) external {
        Order storage order = atomicSwapOrders[_orderId];
        require(
            order.redeemer != address(0x0),
            "AtomicSwap: order not initated"
        );
        require(!order.isFulfilled, "AtomicSwap: order already fulfilled");
        bytes32 secretHash = sha256(_secret);
        require(
            sha256(abi.encode(secretHash, order.initiator)) == _orderId,
            "AtomicSwap: invalid secret"
        );
        order.isFulfilled = true;
        emit Redeemed(_orderId, secretHash, _secret);
        token.safeTransfer(order.redeemer, order.amount);
    }

    /**
     * @notice  Signers can refund the locked assets after expiry block number
     * @dev     Signers cannot refund the an order before epiry block number or refund the same order
     *          multiple times
     * @param   _orderId  orderId of the htlc order
     */
    function refund(bytes32 _orderId) external {
        Order storage order = atomicSwapOrders[_orderId];
        require(
            order.redeemer != address(0x0),
            "AtomicSwap: order not initated"
        );
        require(!order.isFulfilled, "AtomicSwap: order already fulfilled");
        require(
            order.initiatedAt + order.expiry < block.number,
            "AtomicSwap: order not expired"
        );
        order.isFulfilled = true;
        emit Refunded(_orderId);
        token.safeTransfer(order.initiator, order.amount);
    }
}
