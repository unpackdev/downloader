// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Verifier.sol";
import "./MerkleTreeWithHistory.sol";
import "./ReentrancyGuard.sol";

contract StealthWrappedETH is ERC20, Verifier, MerkleTreeWithHistory, ReentrancyGuard {
    /********************************/
    /* swETH Public Methods         */
    /********************************/
    mapping (address => bytes32) _privateHashBalance;
    mapping (address => bytes) public _privateEncryptedBalances;
    mapping (bytes32 => bool) public nullifierHashes;
    mapping(bytes32 => bool) public commitments;

    event PrivateTransferCompleted(
        address indexed receiver,
        bytes32 indexed nullifierHash,
        uint256 timestamp
    );
    event PrivateTransferInitiated(
        bytes32 indexed commitment,
        address indexed sender,
        uint32 indexed insertedIndex,
        bytes sharedSecret,
        uint256 timestamp
    );

    constructor(
        uint32 _merkleTreeHeight,
        IHasher _hasher
    ) MerkleTreeWithHistory(_merkleTreeHeight, _hasher) {
    }

    receive() external payable {
        deposit();
    }

    /**
     * @dev Converts native ETH into swETH public balance
     */
    function deposit() public payable nonReentrant {
        _deposit(msg.value, msg.sender);
    }

    /**
     * @dev Converts swETH public balance back into native ETH
     */
    function withdraw(uint256 amount) public nonReentrant {
        _withdraw(amount, msg.sender);
    }

    /**
     * @dev Converts public balance intro private balance
     */
    function wrap(uint256 amount, bytes32 hashReceiverBalanceAfter, bytes calldata encryptedReceiverNewBalance, bytes calldata zkProofReceiver) public {
        _wrap(amount, msg.sender, hashReceiverBalanceAfter, encryptedReceiverNewBalance, zkProofReceiver);
    }

    /**
     * @dev Converts private balance into public balance
     */
    function unwrap(uint256 amount, bytes32 hashReceiverBalanceAfter, bytes calldata encryptedReceiverNewBalance, uint256 relayerFeeAmount, address relayerFeeReceiver, address receiver, bytes calldata zkProofReceiver) public {
        _unwrap(amount, receiver, hashReceiverBalanceAfter, encryptedReceiverNewBalance, relayerFeeAmount, relayerFeeReceiver, zkProofReceiver);
    }

    /**
     * @dev Converts native ETH into swETH private balance
     */
    function depositAndWrap(bytes32 hashReceiverBalanceAfter, bytes calldata encryptedReceiverNewBalance, bytes calldata zkProofReceiver) external payable nonReentrant {
        _deposit(msg.value, msg.sender);
        wrap(msg.value, hashReceiverBalanceAfter, encryptedReceiverNewBalance, zkProofReceiver);
    }

    /**
     * @dev Converts private swETH back into native ETH
     */
    function unwrapAndWithdraw(uint256 amount, bytes32 hashReceiverBalanceAfter, bytes calldata encryptedReceiverNewBalance, uint256 relayerFeeAmount, address relayerFeeReceiver, address receiver, bytes calldata zkProofReceiver) external nonReentrant {
        unwrap(amount, hashReceiverBalanceAfter, encryptedReceiverNewBalance, relayerFeeAmount, relayerFeeReceiver, receiver, zkProofReceiver);
        _withdraw(amount, receiver);
    }

    /**
     * @dev Starts a transfer with private balance
     */
    function initiatePrivateTransfer(
        bytes32 commitment,
        bytes memory sharedSecret,
        bytes memory encryptedSenderNewBalance,
        bytes32 hashSenderBalanceAfter,
        bytes calldata zkProofSender
    ) external {
        require(!commitments[commitment], "The commitment has been submitted");
        uint32 insertedIndex = _insert(commitment);
        commitments[commitment] = true;

        require(verifyProofInitTransfer(
            zkProofSender,
            [
                bytes32ToUint(getHashBalance(msg.sender)),
                bytes32ToUint(hashSenderBalanceAfter),
                bytes32ToUint(commitment)
            ]
        ), "INCORRECT_PROOF");

        _privateEncryptedBalances[msg.sender] = encryptedSenderNewBalance;
        _privateHashBalance[msg.sender] = hashSenderBalanceAfter;

        emit PrivateTransferInitiated(
            commitment,
            msg.sender,
            insertedIndex,
            sharedSecret,
            block.timestamp
        );
    }

    /**
     * @dev Finishes a private transfer updating encrypted balances.
     */
    function completePrivateTransfer(
        bytes32 root,
        bytes32 nullifierHash,
        bytes32 hashReceiverBalanceAfter,
        bytes calldata encryptedReceiverNewBalance,
        uint256 relayerFeeAmount,
        address relayerFeeReceiver,
        address receiver,
        bytes calldata zkProofReceiver
    ) external nonReentrant {
        require(!nullifierHashes[nullifierHash], "This transfer has already been completed");
        require(isKnownRoot(root), "Cannot find your merkle root"); // Make sure to use a recent one

        require(verifyProofCompleteTransfer(
            zkProofReceiver,
            [
                uint256(root),
                uint256(nullifierHash),
                bytes32ToUint(getHashBalance(receiver)),
                bytes32ToUint(hashReceiverBalanceAfter),
                relayerFeeAmount,
                uint160(receiver),
                uint160(ripemd160(abi.encodePacked(encryptedReceiverNewBalance)))
            ]
        ), "INCORRECT_PROOF");

        _privateEncryptedBalances[receiver] = encryptedReceiverNewBalance;
        _privateHashBalance[receiver] = hashReceiverBalanceAfter;
    
        nullifierHashes[nullifierHash] = true;
        emit PrivateTransferCompleted(receiver, nullifierHash, block.timestamp);

        if (relayerFeeAmount > 0) {
            _mint(relayerFeeReceiver, relayerFeeAmount);
        }
    }

    function getHashBalance(address wallet) public view returns (bytes32) {
        bytes32 hashReceiverBalanceBefore = _privateHashBalance[wallet];
        if (hashReceiverBalanceBefore == 0) {
            return 0x0692f4456bb164c2cf0f2fd18977e4de9969750d28100417b8653acce5278ca2; // Pedersen hash computed for 0 balance and 0 as a salt.
        }
        return hashReceiverBalanceBefore;
    }

    /********************************/
    /* swETH Utils Methods          */
    /********************************/
    function bytesToUint(bytes16 b) public pure returns (uint128){
        return uint128(b);
    }

    function bytes32ToUint(bytes32 b) public pure returns (uint256){
        return uint256(b);
    }

    function uintToBytes(uint128 a) public pure returns(bytes16) {
        return bytes16(a);
    }

    function concatBytes(bytes16 a, bytes16 b) public pure returns (bytes32) {
        return bytes32 (uint256 (uint128 (a)) << 128 | uint128 (b));
    }

    function byte32To16(bytes32 sha) public pure returns (bytes16 half1, bytes16 half2) {
        assembly {
            let freemem_pointer := mload(0x40)
            mstore(add(freemem_pointer,0x00), sha)
            half1 := mload(add(freemem_pointer,0x00))
            half2 := mload(add(freemem_pointer,0x10))
        }
    }

    /********************************/
    /* swETH Private Methods        */
    /********************************/
    function _deposit(uint256 amount, address receiver) internal {
        require(msg.value == amount, "INCORRECT_VALUE");
        _mint(receiver, amount);
    }

    function _withdraw(uint256 amount, address receiver) internal {
        _burn(receiver, amount);
        payable(receiver).transfer(amount);
    }

    function _wrap(
        uint256 amount, 
        address wallet, 
        bytes32 hashReceiverBalanceAfter, 
        bytes calldata encryptedReceiverNewBalance, 
        bytes calldata zkProofReceiver
    ) internal {
        _burn(wallet, amount);
        bytes32 hashReceiverBalanceBefore = getHashBalance(wallet);

        bool receiverProofIsCorrect = verifyProofWrap(
            zkProofReceiver,
            [
                amount,
                bytes32ToUint(hashReceiverBalanceBefore),
                bytes32ToUint(hashReceiverBalanceAfter)
            ]
        );
        require(receiverProofIsCorrect, "INCORRECT_PROOF");
        
        _privateEncryptedBalances[wallet] = encryptedReceiverNewBalance;
        _privateHashBalance[wallet] = hashReceiverBalanceAfter;
    }

    function _unwrap(
        uint256 amount, 
        address receiver, 
        bytes32 hashReceiverBalanceAfter, 
        bytes calldata encryptedReceiverNewBalance,
        uint256 relayerFeeAmount,
        address relayerFeeReceiver,
        bytes calldata zkProofReceiver
    ) internal {
        bytes32 hashReceiverBalanceBefore = getHashBalance(receiver);

        bool receiverProofIsCorrect = verifyProofUnwrap(
            zkProofReceiver,
            [
                amount,
                bytes32ToUint(hashReceiverBalanceBefore),
                bytes32ToUint(hashReceiverBalanceAfter),
                relayerFeeAmount,
                uint160(receiver),
                uint160(ripemd160(abi.encodePacked(encryptedReceiverNewBalance)))
            ]
        );
        require(receiverProofIsCorrect, "INCORRECT_PROOF");

        _privateEncryptedBalances[receiver] = encryptedReceiverNewBalance;        
        _privateHashBalance[receiver] = hashReceiverBalanceAfter;

        _mint(receiver, amount);

        if (relayerFeeAmount > 0) {
            _mint(relayerFeeReceiver, relayerFeeAmount);
        }
    }
}
