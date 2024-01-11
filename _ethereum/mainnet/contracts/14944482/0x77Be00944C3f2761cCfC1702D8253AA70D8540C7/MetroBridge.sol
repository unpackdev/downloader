// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./MetToken.sol";

contract MetroBridge is EIP712, Ownable {

  enum Operation {
    BURN_MET,
    MINT_MET
  }

  struct Transaction {
    address sender;
    Operation operation;
    uint256 amount;
    uint256 nonce;
    uint256 expirationTimestamp;
    bytes16 bridgeTransactionId;
  }

  bytes32 constant TRANSACTION_STRUCT_HASH = keccak256("Transaction(address sender,uint8 operation,uint256 amount,uint256 nonce,uint256 expirationTimestamp,bytes16 bridgeTransactionId)");

  address public signerAddress;
  address immutable public metTokenAddress;

  uint256 public transactionMetLimit = 10_000_000 ether;

  mapping(address => uint256) public nonces;

  event BurnedMET(address indexed sender, bytes16 indexed bridgeTransactionId, uint256 nonce, uint256 amount);
  event MintedMET(address indexed sender, bytes16 indexed bridgeTransactionId, uint256 nonce, uint256 amount);

  constructor(address _signerAddress, address _metTokenAddress) EIP712('MetroBridge', '1') {
    signerAddress = _signerAddress;
    metTokenAddress = _metTokenAddress;
  }

  function setSignerAddress(address _signerAddress) external onlyOwner {
    signerAddress = _signerAddress;
  }

  function setTransactionMetLimit(uint256 _transactionMetLimit) external onlyOwner {
    transactionMetLimit = _transactionMetLimit;
  }

  function buildStructHash(Transaction calldata transaction) private pure returns (bytes32) {
    return keccak256(
      abi.encode(
        TRANSACTION_STRUCT_HASH,
        transaction.sender,
        transaction.operation,
        transaction.amount,
        transaction.nonce,
        transaction.expirationTimestamp,
        transaction.bridgeTransactionId
      )
    );
  }

  function executeSignedTransaction(Transaction calldata transaction, bytes32 signatureR, bytes32 signatureVS) external {
    require(msg.sender == transaction.sender, 'Sender does not match');
    require(nonces[transaction.sender]++ == transaction.nonce, 'Invalid nonce');
    require(block.timestamp < transaction.expirationTimestamp, 'Signed transaction expired');
    require(transaction.amount <= transactionMetLimit, 'Exceeded MET transaction limit');

    bytes32 structHash = buildStructHash(transaction);
    bytes32 hash = _hashTypedDataV4(structHash);
    address signer = ECDSA.recover(hash, signatureR, signatureVS);

    require(signer != address(0), 'Invalid signature');
    require(signer == signerAddress, 'Invalid signer');

    if (transaction.operation == Operation.BURN_MET) {
      MetToken(metTokenAddress).burnFrom(transaction.sender, transaction.amount);
      emit BurnedMET(transaction.sender, transaction.bridgeTransactionId, transaction.nonce, transaction.amount);
    } else if (transaction.operation == Operation.MINT_MET) {
      MetToken(metTokenAddress).mint(transaction.sender, transaction.amount);
      emit MintedMET(transaction.sender, transaction.bridgeTransactionId, transaction.nonce, transaction.amount);
    } else {
      require(false, 'Invalid operation');
    }
  }
}