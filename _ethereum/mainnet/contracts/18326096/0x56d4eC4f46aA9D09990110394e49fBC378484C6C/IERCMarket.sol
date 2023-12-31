// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./IIERCMarket.sol";
import "./OrderTypes.sol";
import "./SignatureChecker.sol";

/**
 * @title IERCMarket
 * @notice It is the core contract of the ierc.market ethscription exchange.
 */
contract IERCMarket is
    IIERCMarket,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using OrderTypes for OrderTypes.EthscriptionOrder;

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    bytes32 internal constant WITHDRAW_ETHSCRIPTION_HASH =
        keccak256("WithdrawEthscription(bytes32 ethscriptionId,address recipient,uint64 expiration)");

    address private trustedVerifier;

    mapping(address => uint256) public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;
    mapping(address => mapping(bytes32 => uint256)) private _ethscriptionDepositedOnBlockNumber;

    uint256 internal constant TRANSFER_BLOCK_CONFIRMATIONS = 5;

    mapping(bytes32 => uint256) private _ethscriptionWithdrawOnBlockNumber;

    function initialize() public initializer {
        __EIP712_init("IERCMarket", "1");
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    fallback() external {}

    receive() external payable {}

    function executeEthscriptionOrder(
        OrderTypes.EthscriptionOrder calldata order,
        address recipient,
        bytes calldata /*data*/
    ) public payable override nonReentrant whenNotPaused {
        // Check the maker ask order
        bytes32 orderHash = _verifyOrderHash(order);

        // Execute the transaction
        _executeOrder(order, orderHash, recipient);
    }

    /**
     * @notice Cancel all pending orders for a sender
     */
    function cancelAllOrders() public override {
        userMinOrderNonce[msg.sender] = block.timestamp;
        emit CancelAllOrders(msg.sender, block.timestamp, uint64(block.timestamp));
    }

    /**
     * @notice Cancel maker orders
     * @param orderNonces array of order nonces
     */
    function cancelMultipleMakerOrders(uint256[] calldata orderNonces) public override {
        if (orderNonces.length == 0) {
            revert EmptyOrderCancelList();
        }
        for (uint256 i = 0; i < orderNonces.length; i++) {
            if (orderNonces[i] < userMinOrderNonce[msg.sender]) {
                revert OrderNonceTooLow();
            }
            _isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
        }
        emit CancelMultipleOrders(msg.sender, orderNonces, uint64(block.timestamp));
    }

    function withdrawEthscription(
        bytes32 ethscriptionId,
        uint64 expiration,
        bytes calldata trustedSign
    ) public override whenNotPaused {
        if (expiration < block.timestamp) {
            revert ExpiredSignature();
        }

        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(trustedSign);
        bytes32 digest = keccak256(abi.encode(WITHDRAW_ETHSCRIPTION_HASH, ethscriptionId, msg.sender, expiration));
        (bool isValid, ) = SignatureChecker.verify(digest, trustedVerifier, v, r, s, _domainSeparatorV4());
        if (!isValid) {
            revert TrustedSignatureInvalid();
        }

        _ethscriptionWithdrawOnBlockNumber[ethscriptionId] = block.number;

        emit ethscriptions_protocol_TransferEthscriptionForPreviousOwner(msg.sender, msg.sender, ethscriptionId);
        emit EthscriptionWithdrawn(msg.sender, ethscriptionId, uint64(block.timestamp));
    }

    /**
     * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
    }

    function updateTrustedVerifier(address _trustedVerifier) external onlyOwner {
        trustedVerifier = _trustedVerifier;
        emit NewTrustedVerifier(_trustedVerifier);
    }

    function pause() public onlyOwner {
        PausableUpgradeable._pause();
    }

    function unpause() public onlyOwner {
        PausableUpgradeable._unpause();
    }

    function _executeOrder(OrderTypes.EthscriptionOrder calldata order, bytes32 orderHash, address recipient) internal {
        if (order.price != msg.value) {
            revert MsgValueInvalid();
        }

        // Verify the recipient is not address(0)
        require(recipient != address(0), "invalid recipient");

        // Verify whether order has expired
        if (
            (order.startTime > block.timestamp) ||
            (order.endTime < block.timestamp) ||
            block.number < (_ethscriptionWithdrawOnBlockNumber[order.ethscriptionId] + TRANSFER_BLOCK_CONFIRMATIONS)
        ) {
            revert OrderExpired();
        }

        // Update order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[order.signer][order.nonce] = true;

        // Pay fees
        _transferFees(order);

        emit ethscriptions_protocol_TransferEthscriptionForPreviousOwner(order.signer, recipient, order.ethscriptionId);

        emit EthscriptionOrderExecuted(
            orderHash,
            order.nonce,
            order.ethscriptionId,
            order.quantity,
            order.signer,
            recipient,
            order.currency,
            order.price,
            uint64(block.timestamp)
        );
    }

    function _transferFees(OrderTypes.EthscriptionOrder calldata order) internal {
        uint256 finalSellerAmount = order.price;

        // Pay protocol fee
        if (order.protocolFeeDiscounted != 0) {
            uint256 protocolFeeAmount = (order.protocolFeeDiscounted * order.price) / 10000;
            finalSellerAmount -= protocolFeeAmount;
        }

        // Pay creator fee
        if (order.creator != address(0) && order.creatorFee != 0) {
            uint256 creatorFeeAmount = (order.creatorFee * order.price) / 10000;
            finalSellerAmount -= creatorFeeAmount;
            if (order.creator != address(this)) {
                _transferETHWithGasLimit(order.creator, creatorFeeAmount, 5000);
            }
        }

        _transferETHWithGasLimit(order.signer, finalSellerAmount, _GAS_STIPEND_NO_STORAGE_WRITES);
    }

    /**
     * @notice It transfers ETH to a recipient with a specified gas limit.
     * @param to Recipient address
     * @param amount Amount to transfer
     * @param gasLimit Gas limit to perform the ETH transfer
     */
    function _transferETHWithGasLimit(address to, uint256 amount, uint256 gasLimit) internal {
        bool success;
        assembly {
            success := call(gasLimit, to, amount, 0, 0, 0, 0)
        }
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /**
     * @notice Verify the validity of the ethscription order
     * @param order maker ethscription order
     */
    function _verifyOrderHash(OrderTypes.EthscriptionOrder calldata order) internal view returns (bytes32) {
        // Verify whether order nonce has expired
        if (
            _isUserOrderNonceExecutedOrCancelled[order.signer][order.nonce] ||
            (order.nonce < userMinOrderNonce[order.signer])
        ) {
            revert NoncesInvalid();
        }

        // Verify the signer is not address(0)
        if (order.signer == address(0)) {
            revert SignerInvalid();
        }
        bytes32 orderHash = order.hash();

        // Verify the validity of the signature
        (bool isValid, bytes32 digest) = SignatureChecker.verify(
            orderHash,
            order.signer,
            order.v,
            order.r,
            order.s,
            _domainSeparatorV4()
        );
        if (!isValid) {
            revert SignatureInvalid();
        }
        return digest;
    }

    function _splitSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (signature.length != 65) {
            revert SignatureInvalid();
        }

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        Address.sendValue(to, amount);
    }

    function withdrawUnexpectedERC20(address token, address to, uint256 amount) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }
}