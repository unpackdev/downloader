// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ICurrencyManager.sol";
import "./ICarpenterMarket.sol";
import "./OrderTypes.sol";
import "./MerkleProof.sol";
import "./SignatureChecker.sol";

/**
 * @title CarpenterMarket
 * @notice It is the core contract of the carpenter.market ethscription exchange.
 */
contract CarpenterMarket is
    ICarpenterMarket,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using OrderTypes for OrderTypes.EthscriptionOrder;
    using BatchOrder for BatchOrder.EthscriptionOrder;

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    bytes32 internal constant WITHDRAW_ETHSCRIPTION_HASH =
        keccak256("WithdrawEthscription(bytes32 ethscriptionId,address recipient,uint64 expiration)");

    ICurrencyManager public currencyManager;
    uint16 public creatorFeeBps;
    uint16 public protocolFeeBps;
    address public protocolFeeRecipient;
    address private trustedVerifier;

    mapping(address => uint256) public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;
    mapping(address => mapping(bytes32 => uint256)) private _ethscriptionDepositedOnBlockNumber;

    uint256 internal constant TRANSFER_BLOCK_CONFIRMATIONS = 20; // TODO find the best value

    mapping(bytes32 => uint256) private _ethscriptionWithdrawOnBlockNumber;

    function initialize() public initializer {
        __EIP712_init("CarpenterMarket", "1");
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
        _verifyBlockNumber(order.params);
        _executeOrder(order, orderHash, recipient);
    }

    function executeOrderWithMerkle(
        BatchOrder.EthscriptionOrder calldata order,
        BatchOrder.MerkleTree calldata merkleTree,
        address recipient
    ) public payable override nonReentrant whenNotPaused {
        bytes32 orderHash = _verifyMerkleProofOrOrderHash(order, merkleTree);
        _verifyBlockNumber(order.params);
        _executeBatchOrder(order, orderHash, recipient);
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

    function updateProtocolFeeBps(uint16 _protocolFeeBps) external onlyOwner {
        protocolFeeBps = _protocolFeeBps;
        emit NewProtocolFeeBps(_protocolFeeBps);
    }

    function updateTrustedVerifier(address _trustedVerifier) external onlyOwner {
        trustedVerifier = _trustedVerifier;
        emit NewTrustedVerifier(_trustedVerifier);
    }

    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
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
        _transferFees(order.signer, order.creator, order.price, order.protocolFeeDiscounted, order.creatorFee);

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

    function _executeBatchOrder(
        BatchOrder.EthscriptionOrder calldata order,
        bytes32 orderHash,
        address recipient
    ) internal {
        if (order.price != msg.value) {
            revert MsgValueInvalid();
        }
        // Verify the recipient is not address(0)
        if (recipient == address(0)) {
            revert RecipientInvalid();
        }
        // Verify whether order has expired
        if ((order.startTime > block.timestamp) || (order.endTime < block.timestamp)) {
            revert OrderExpired();
        }

        // Update order status to true (prevents replay)
        _isUserOrderNonceExecutedOrCancelled[order.signer][order.nonce] = true;

        // Pay fees
        _transferFees(order.signer, order.creator, order.price, order.protocolFeeDiscounted, order.creatorFee);

        for (uint256 i = 0; i < order.ethscriptionIds.length; i++) {
            if (
                block.number <
                (_ethscriptionWithdrawOnBlockNumber[order.ethscriptionIds[i]] + TRANSFER_BLOCK_CONFIRMATIONS)
            ) {
                revert OrderExpired();
            }
            _ethscriptionWithdrawOnBlockNumber[order.ethscriptionIds[i]] = block.number;

            emit ethscriptions_protocol_TransferEthscriptionForPreviousOwner(
                order.signer,
                recipient,
                order.ethscriptionIds[i]
            );

            emit EthscriptionOrderExecuted(
                orderHash,
                order.nonce,
                order.ethscriptionIds[i],
                order.quantities[i],
                order.signer,
                recipient,
                order.currency,
                order.price,
                uint64(block.timestamp)
            );
        }
    }

    function _transferFees(
        address signer,
        address creator,
        uint256 price,
        uint16 protocolFeeDiscounted,
        uint16 creatorFee
    ) internal {
        uint256 finalSellerAmount = price;

        // Pay protocol fee
         if (protocolFeeDiscounted != 0) {
             uint256 protocolFeeAmount = (protocolFeeDiscounted * price) / 10000;
             finalSellerAmount -= protocolFeeAmount;
         }

        // Pay creator fee
        if (creator != address(0) && creatorFee != 0) {
            uint256 creatorFeeAmount = (creatorFee * price) / 10000;
            finalSellerAmount -= creatorFeeAmount;
            if (creator != address(this)) {
                _transferETHWithGasLimit(creator, creatorFeeAmount, 5000);
            }
        }

        _transferETHWithGasLimit(signer, finalSellerAmount, _GAS_STIPEND_NO_STORAGE_WRITES);
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

    function _verifyBlockNumber(bytes calldata params) internal view {
        if (params.length == 0) {
            return;
        }
        uint256 blockNumber = abi.decode(params, (uint256));
        bytes32 blockHash = abi.decode(params[32:], (bytes32));
        bytes32 blockHashOnChain = blockhash(blockNumber);
        if (blockHashOnChain != 0 && blockHashOnChain != blockHash) {
            revert("block hash mismatch");
        }
    }

    /**
     * @notice This function is private and called to verify whether the merkle proofs provided for the order hash
     *         are correct or verify the order hash if the order is not part of a merkle tree.
     * @param order maker ethscription order
     * @param merkleTree Merkle tree
     * @dev It verifies (1) merkle proof (if necessary) (2) signature is from the expected signer
     */
    function _verifyMerkleProofOrOrderHash(
        BatchOrder.EthscriptionOrder calldata order,
        BatchOrder.MerkleTree calldata merkleTree
    ) internal view returns (bytes32) {
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

        bytes32 orderHash;

        uint256 proofLength = merkleTree.proof.length;
        bytes32 digest;

        if (proofLength != 0) {
            if (proofLength > 10) {
                revert MerkleProofTooLarge(proofLength);
            }

            orderHash = order.bundleHash();
            digest = keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), orderHash));

            if (!MerkleProof.verifyCalldata(merkleTree.proof, merkleTree.root, orderHash)) {
                revert MerkleProofInvalid();
            }

            orderHash = hashBatchOrder(merkleTree.root, proofLength, true);
        } else {
            if (order.ethscriptionIds.length > 1) {
                orderHash = order.bundleHash();
            } else {
                orderHash = order.singleHash();
            }

            digest = keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), orderHash));
        }


        // Verify the validity of the signature
        (bool isValid, ) = SignatureChecker.verify(
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

    /**
     * @notice This function returns the hash of the concatenation of batch order type hash and merkle root.
     * @param root Merkle root
     * @param proofLength Merkle proof length
     * @return batchOrderHash The batch order hash
     */
    function hashBatchOrder(bytes32 root, uint256 proofLength, bool isBundle) public pure returns (bytes32 batchOrderHash) {
        if (isBundle) {
            batchOrderHash = keccak256(abi.encode(_getBatchBundleOrderTypeHash(proofLength), root));
        } else {
            batchOrderHash = keccak256(abi.encode(_getBatchOrderTypeHash(proofLength), root));
        }
    }

    /**
     * @dev It looks like this for each height
     *      height == 1: BatchOrder(EthscriptionOrder[2] tree)EthscriptionOrder(address signer,address creator,bytes32 ethscriptionId,uint256 quantity,address currency,uint256 price,uint256 nonce,uint64 startTime,uint64 endTime,uint16 protocolFeeDiscounted,uint16 creatorFee,bytes params)
     *      height == 2: BatchOrder(EthscriptionOrder[2][2] tree)EthscriptionOrder(address signer,address creator,bytes32 ethscriptionId,uint256 quantity,address currency,uint256 price,uint256 nonce,uint64 startTime,uint64 endTime,uint16 protocolFeeDiscounted,uint16 creatorFee,bytes params)
     *      height == n: BatchOrder(EthscriptionOrder[2]...[2] tree)EthscriptionOrder(address signer,address creator,bytes32 ethscriptionId,uint256 quantity,address currency,uint256 price,uint256 nonce,uint64 startTime,uint64 endTime,uint16 protocolFeeDiscounted,uint16 creatorFee,bytes params)
     */
    function _getBatchOrderTypeHash(uint256 height) internal pure returns (bytes32 typeHash) {
        if (height == 1) {
            typeHash = hex"653c18b351f84a01421715d3342da5312956b7e934453b59579577e34f4fcafa";
        } else if (height == 2) {
            typeHash = hex"b4a7afe3cd3f39b74a443d5b04664e271bca994e05a45ea699ae435a06cd2c52";
        } else if (height == 3) {
            typeHash = hex"472c3c6ac7e1590bf019e2cbf7b46b9ac36e2ff35e2e95955c0f435c70009e9e";
        } else if (height == 4) {
            typeHash = hex"4bf7f0f268dd3c44e2979e118513c20c47051971fe31306cc0c8870289ccf858";
        } else if (height == 5) {
            typeHash = hex"dcc529aae4ec2b6d8e8105f909683a76f2e20f7d883ff1883d184a00584d1889";
        } else if (height == 6) {
            typeHash = hex"2e77b0fcdcb0d62e2307ace8c5423060bcc09b20520aebb872362e8c92699845";
        } else if (height == 7) {
            typeHash = hex"6b4f5670e54bd04f2f0521d9e614369102d9e7b80ff81405d87f5206f939ff2d";
        } else if (height == 8) {
            typeHash = hex"11cfeff3744665039fe9f82578739948c768d3e7ddc9a17ac2613d4ad236d698";
        } else if (height == 9) {
            typeHash = hex"3e58bccb5cfac571cdc0a3a2c0eae8f5f6b24fb8739627e1b2741d7d42317098";
        } else if (height == 10) {
            typeHash = hex"4648307183d10560dcda782cbdbf91ed1e05be07014932e83dbcf5c66c714abf";
        } else {
            revert MerkleProofTooLarge(height);
        }
    }

    /**
     * @dev It looks like this for each height
     *      height == 1: BatchOrder(EthscriptionOrder[2] tree)EthscriptionOrder(address signer,address creator,bytes32[] ethscriptionIds,uint256[] quantities,address currency,uint256 price,uint256 nonce,uint64 startTime,uint64 endTime,uint16 protocolFeeDiscounted,uint16 creatorFee,bytes params)
     *      height == 2: BatchOrder(EthscriptionOrder[2][2] tree)EthscriptionOrder(address signer,address creator,bytes32[] ethscriptionIds,uint256[] quantities,address currency,uint256 price,uint256 nonce,uint64 startTime,uint64 endTime,uint16 protocolFeeDiscounted,uint16 creatorFee,bytes params)
     *      height == n: BatchOrder(EthscriptionOrder[2]...[2] tree)EthscriptionOrder(address signer,address creator,bytes32[] ethscriptionIds,uint256[] quantities,address currency,uint256 price,uint256 nonce,uint64 startTime,uint64 endTime,uint16 protocolFeeDiscounted,uint16 creatorFee,bytes params)
     */
    function _getBatchBundleOrderTypeHash(uint256 height) internal pure returns (bytes32 typeHash) {
        if (height == 1) {
            typeHash = hex"f64a526fd7ed95a20fce378c9221c30637cae53836ccc3716932bdb7a26e0196";
        } else if (height == 2) {
            typeHash = hex"b5a1836a244e7d7f8348af094530db0567ca18d2ca80e7a53dab3c648924e0d8";
        } else if (height == 3) {
            typeHash = hex"a3a6ed47a8f0aa879fe8cb6edd3e581911d5ef364f29c789e941f892843b38c3";
        } else if (height == 4) {
            typeHash = hex"d21c033e994b239a72a2eb149479c8a83dce2ea85d60ed05bd78a6ffa9873d7e";
        } else if (height == 5) {
            typeHash = hex"1d569ffb81ef4d35697ec3bb9526320e92bb8b27e8d9e2d951f0c1462ac335d2";
        } else if (height == 6) {
            typeHash = hex"f263d279bc1e721236042c36c865c4db9e3976dbe94f696b1598381dcad7ba28";
        } else if (height == 7) {
            typeHash = hex"59a3c483cdad040defc786cff37c6be0e19415791802fb9c79ccbaa7a3580d78";
        } else if (height == 8) {
            typeHash = hex"0df415331f97d8a9cfca8ed50e9d19fa6c641987160070cb4f3ccabdd207bfac";
        } else if (height == 9) {
            typeHash = hex"de2cf5bd5dcdcc34cf0c7095dcd12dbf3996d28b1bcb6bf5253d77df191f64e6";
        } else if (height == 10) {
            typeHash = hex"206c9a6543f1a4209ee1798b17f7befaccc036dce993cc1af152f4b9c5aaf71a";
        } else {
            revert MerkleProofTooLarge(height);
        }
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
