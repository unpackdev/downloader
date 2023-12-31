// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract Withdrawal is Pausable, Ownable {
    event WithdrawalEvent(uint256 indexed key, address signer, address to, address indexed token, uint256 amount);
    event CancelEvent(uint256 indexed key, address signer, address to, address indexed token, uint256 amount);
    event UpdateSigner(address signer, bool value);
    event UpdatePauseOperator(address oldOperator, address newOperator);

    enum OrderStatus {
        None,
        Processed,
        Cancelled
    }

    /* An ECDSA signature. */
    struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Order {
        address signer;
        address holder;
        address to;
        address token;
        uint256 amount;
        uint256 expiration;
        uint256 key;
    }

    mapping(uint256 => OrderStatus) private _status;
    mapping(uint256 => Order) public orders;
    mapping(address => bool) public allowedSigners;
    address public pauseOperator;

    error ExpiredOrder();
    error ProcessedOrder();
    error CancelledOrder();
    error InvalidOrder();
    error InvalidCaller();
    error InvalidSigner();

    modifier onlyPauseOperator() {
        if (msg.sender != pauseOperator) revert InvalidCaller();
        _;
    }

    constructor(address pauseOperator_) {
        pauseOperator = pauseOperator_;
    }

    function pause() external onlyPauseOperator {
        _pause();
    }

    function unpause() external onlyPauseOperator {
        _unpause();
    }

    function setAllowedSigner(address signer, bool value) external onlyOwner {
        allowedSigners[signer] = value;
        emit UpdateSigner(signer, value);
    }

    function setPauseOperator(address pauseOperator_) external onlyOwner {
        address oldpauseOperator = pauseOperator;
        pauseOperator = pauseOperator_;
        emit UpdatePauseOperator(oldpauseOperator, pauseOperator_);
    }

    function _getCompletedKey(Order memory order) internal pure returns (uint256) {
        return order.key;
    }

    function withdrawal(Order calldata order, Sig calldata sig) external whenNotPaused {
        validateOrder(order, sig);
        if (order.expiration <= block.timestamp) revert ExpiredOrder();
        uint256 key = _getCompletedKey(order);
        if (_status[key] == OrderStatus.Processed) revert ProcessedOrder();
        if (_status[key] == OrderStatus.Cancelled) revert CancelledOrder();

        _status[key] = OrderStatus.Processed;
        IERC20(order.token).transferFrom(order.holder, order.to, order.amount);
        emit WithdrawalEvent(order.key, order.signer, order.to, order.token, order.amount);
    }

    function cancel(Order calldata order, Sig calldata sig) external whenNotPaused {
        validateOrder(order, sig);
        uint256 key = _getCompletedKey(order);
        if (_status[key] == OrderStatus.Processed) revert ProcessedOrder();
        if (_status[key] == OrderStatus.Cancelled) revert CancelledOrder();

        _status[key] = OrderStatus.Cancelled;
        emit CancelEvent(order.key, order.signer, order.to, order.token, order.amount);
    }

    ///@dev This function will be used in the future
    // function multipleWithdrawal(Order[] calldata order, Sig[] calldata sig) external {
    //     for (uint256 i = 0; i < order.length; i++) {
    //         withdrawal(order[i], sig[i]);
    //     }
    // }

    function validateOrder(Order calldata order, Sig calldata sig) private view {
        bytes32 payloadHash = keccak256(
            abi.encode(order.signer, order.holder, order.to, order.token, order.amount, order.expiration, order.key)
        );
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));

        address actualSigner = ecrecover(messageHash, sig.v, sig.r, sig.s);
        if (order.signer != actualSigner) revert InvalidOrder();
        if (!allowedSigners[actualSigner]) revert InvalidSigner();
    }

    function getCompletedKey(Order calldata order) external pure returns (uint256) {
        return _getCompletedKey(order);
    }

    function getStatus(uint256 key) external view returns (OrderStatus) {
        return _status[key];
    }

    function getOrder(uint256 key) external view returns (Order memory) {
        return orders[key];
    }
}
