// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SignatureCheckerUpgradeable.sol";
import "./TokenTrader.sol";
import "./LibOrder.sol";
import "./IERC20Permit.sol";
import "./IERC721Permit.sol";
import "./IERC1155Permit.sol";

contract Exchange is TokenTrader {
    using LibOrder for LibOrder.Order;
    using LibAsset for LibAsset.Asset;

    uint256 public constant MAX_FEE = 2000; // 20%

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 private constant VERSION_HASH = keccak256("1");

    bytes32 private constant NAME_HASH = keccak256("Exchange");

    enum OrderState {
        None,
        Cancelled,
        Executed
    }

    /// @notice Mapping of order hashes to their states
    mapping(bytes32 => OrderState) public orderStates;

    mapping(address => bool) public currencyEnabled;

    address public treasury;

    uint256 public fee;

    // CONSTRUCTOR

    function initialize(address treasury_, uint256 fee_) external initializer {
        require(treasury_ != address(0), "Exchange: zero address");
        require(fee_ <= MAX_FEE, "Exchange: invalid fee");

        __TokenTrader_init();
        treasury = treasury_;
        fee = fee_;
    }

    // EVENTS

    event OrderCancelled(LibOrder.Order order);

    /// @notice Event emitted when some exchange happens
    event OrderMatch(LibOrder.Order order, address taker);

    // PUBLIC FUNCTIONS

    function cancelOrder(LibOrder.Order memory order) external {
        require(order.account == msg.sender, "Exchange: sender is not order account");
        bytes32 orderHash = order.hashOrder();
        require(orderStates[orderHash] == OrderState.None, "Exchange: order is in wrong state");

        orderStates[orderHash] = OrderState.Cancelled;
        emit OrderCancelled(order);
    }

    function matchOrder(LibOrder.Order memory order, bytes memory permitSig) external payable {
        bytes32 orderHash = order.hashOrder();
        require(orderStates[orderHash] == OrderState.None, "Exchange: order is in wrong state");
        require(
            currencyEnabled[order.payment.getCurrency()],
            "Exchange: payment currency not enabled"
        );

        bytes32 digest = keccak256(abi.encodePacked(uint16(0x1901), domainHash(), orderHash));
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(order.account, digest, order.orderSig),
            "Exchange: invalid signature"
        );

        orderStates[orderHash] = OrderState.Executed;
        order.matchOrder(permitSig, treasury, fee);
        emit OrderMatch(order, msg.sender);
    }

    // RESTRICTED FUNCTIONS

    function setCurrencyEnabled(address currency, bool enabled) external onlyOwner {
        currencyEnabled[currency] = enabled;
    }

    function setTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "Exchange: zero address");
        treasury = treasury_;
    }

    function setFee(uint256 fee_) external onlyOwner {
        require(fee_ <= MAX_FEE, "Exchange: invalid fee");
        fee = fee_;
    }

    // VIEW FUNCTIONS

    function domainHash() public view returns (bytes32) {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        return
            keccak256(
                abi.encode(EIP712_DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH, chainId, address(this))
            );
    }
}
