// SPDX-License-Identifier: LGPL-3.0 license 
pragma solidity ^0.8.0;

/// @title Multisignature wallet by TOZEX inspired by Gnosis Multisignature project for which we added new functionalities like transaction countdown validation and ERC20/ERC721/ERC1155 tokens management.
/// @author Tozex company

import "./MathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./ERC1155ReceiverUpgradeable.sol";
import "./Initializable.sol";
 
contract MultiSigWallet is 
  Initializable,
  OwnableUpgradeable, 
  IERC721ReceiverUpgradeable, 
  ERC1155ReceiverUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint constant public MAX_OWNER_COUNT = 10;


  event Confirmation(address indexed sender, uint indexed transactionId);
  event Revocation(address indexed sender, uint indexed transactionId);
  event Submission(uint indexed transactionId);
  event Execution(uint indexed transactionId);
  event ExecutionFailure(uint indexed transactionId);
  event Deposit(address indexed sender, address indexed token, uint value);
  event ERC20Deposited(address indexed sender, address indexed token, uint value);
  event ERC721Deposited(address indexed sender, address indexed token, uint tokenId);
  event ERC1155Deposited(address indexed sender, address indexed token, uint tokenId, uint value);
  event SignerChangeRequested(address indexed currentSigner, address indexed newSigner);
  event SignerUpdated(address indexed oldSigner, address indexed newSigner);

  mapping(uint => Transaction) public transactions;
  mapping(uint => mapping(address => bool)) public confirmations;
  mapping(address => address) public signerChangeRequests;
  mapping(address => mapping(address => bool)) public signerChangeConfirmations;
  mapping(address => bool) public isSigner;
  address[] public signers;
  uint public required;
  uint public transactionCount;

  enum TokenStandard {
    ERC20,
    ERC721,
    ERC1155,
    USER
  }

  struct Transaction {
    bool executed;
    address payable destination;
    address token;
    bytes data;
    TokenStandard ts;
    uint tokenId;
    uint value;
    uint confirmTimestamp;
    uint txTimestamp;
  }

  modifier signerExists(address signer) {
    require(isSigner[signer], "Signer does not exist");
    _;
  }

  modifier transactionExists(uint transactionId) {
    require(transactions[transactionId].destination != address(0), "Transaction does not exist");
    _;
  }

  modifier confirmed(uint transactionId, address signer) {
    require(confirmations[transactionId][signer], "Transaction is not confirmed by the signer");
    _;
  }

  modifier notConfirmed(uint transactionId, address signer) {
    require(!confirmations[transactionId][signer], "Transaction already confirmed");
    _;
  }

  modifier notExecuted(uint transactionId) {
    require(!transactions[transactionId].executed, "Transaction already executed");
    _;
  }

  modifier notNull(address _address) {
    require(_address != address(0), "Address cannot be null");
    _;
  }

  modifier validRequirement(uint _signerCount, uint _required) {
    require(_signerCount <= MAX_OWNER_COUNT && required <= _signerCount && _required != 0 && _signerCount != 0, "Invalid requirement");
    _;
  }

  /** 
   * @dev Fallback function allows to deposit ether.
   */
  receive() external payable {
    if (msg.value > 0)
      emit Deposit(msg.sender, address(0), msg.value);
  }
  
  /**
   * Public functions
   * @dev Contract constructor sets initial signers and required number of confirmations.
   * @param _signers List of initial signers.
   * @param _required Number of required confirmations.
   */
  function initialize(address[] memory _signers, uint _required) external initializer validRequirement(_signers.length, _required) {
    __Ownable_init();
    
    for (uint i = 0; i < _signers.length; ) {
      require(!isSigner[_signers[i]] && _signers[i] != address(0) && _signers[i] != msg.sender, "Invalid signer");
      isSigner[_signers[i]] = true;

      unchecked {
        i++;
      }
    }
    signers = _signers;
    required = _required;
  }

  /**
    * @dev Transfers ownership of the contract to a new account (`newOwner`).
    * Can only be called by the current owner.
    */
  function transferOwnership(address newOwner) public override virtual onlyOwner {
      require(!isSigner[newOwner], "Ownable: new owner cannot be signer.");
      super.transferOwnership(newOwner);
  }

  /** 
   * @notice Allows the owner to request a change of signer.
   * @param _oldSigner The address of the current signer to be replaced.
   * @param _newSigner The address of the new signer to be added.
   */
  function requestSignerChange(address _oldSigner, address _newSigner) external onlyOwner {
    require(isSigner[_oldSigner], "Old signer does not exist.");
    require(!isSigner[_newSigner], "New signer is already a signer.");
    require(_newSigner != owner(), "Onwer cannot be a signer.");
    
    // Clear the signerChangeConfirmations for _newSigner if a change is "in-progress"
    if (signerChangeRequests[_oldSigner] != address(0)) {
        clearSignerChangeConfirmations(signerChangeRequests[_oldSigner]);
    }

    signerChangeRequests[_oldSigner] = _newSigner;
    emit SignerChangeRequested(_oldSigner, _newSigner);
  }

  /**
   * @notice Allows a signer to confirm a signer change requested by the owner.
   * @param _oldSigner The address of the current signer to be replaced.
   * @param _newSigner The address of the new signer to be added.
   */
  function confirmSignerChange(address _oldSigner, address _newSigner) external signerExists(msg.sender) {
    require(!signerChangeConfirmations[_newSigner][msg.sender], "You already confirmed.");
    require(signerChangeRequests[_oldSigner] == _newSigner, "New signer address invalid.");
    require(_newSigner != address(0), "No pending signer update request.");
    require(_newSigner != owner(), "Onwer cannot be a signer.");
    require(!isSigner[_newSigner], "New signer is already a signer.");

    // Confirm the update by the current signer
    signerChangeConfirmations[_newSigner][msg.sender] = true;
    
    if (isSignerChangeConfirmed(_newSigner)) {
      // Clear the signerChangeConfirmations for _newSigner
      clearSignerChangeConfirmations(_newSigner);

      signerChangeRequests[_oldSigner] = address(0);
      removeSigner(_oldSigner);
      isSigner[_newSigner] = true;
      signers.push(_newSigner);
      emit SignerUpdated(_oldSigner, _newSigner);
    }
  }

  function depositERC20(address token, uint amount) external {
    require(token != address(0) , "invalid token");
    require(amount > 0 , "invalid amount");
    IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
    emit ERC20Deposited(msg.sender, token, amount); 
  }

  function depositERC721(address token, uint tokenId) external {
    // Transfer the ERC721 token to the multisig contract
    IERC721Upgradeable(token).safeTransferFrom(msg.sender, address(this), tokenId);
    emit ERC721Deposited(msg.sender, token, tokenId);
  }

  function depositERC1155(address token, uint tokenId, uint amount) external {
    // Transfer the ERC1155 tokens to the multisig contract
    IERC1155Upgradeable(token).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
    emit ERC1155Deposited(msg.sender, token, tokenId, amount);
  }

  /**
   * @dev Allows an signer to submit and confirm a transaction.
   * @param destination Transaction target address.
   * @param value Transaction ether value.
   * @param data Transaction data payload.
   */
  function submitTransaction(address payable destination, address token, TokenStandard ts, uint tokenId, uint value, bytes memory data, uint confirmTimestamp) public signerExists(msg.sender) returns (uint transactionId) {
    uint txTimestamp = _getNow();
    transactionId = addTransaction(destination, token, ts, tokenId, value, data, confirmTimestamp, txTimestamp);
    confirmTransaction(transactionId);
  }
 
  /**
   * @dev Allows an signer to confirm a transaction.
   * @param transactionId Transaction ID.
   */
  function confirmTransaction(uint transactionId) public signerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
    require(!isTransactionTimedOut(transactionId), "Transaction timed out.");
    confirmations[transactionId][msg.sender] = true;
    emit Confirmation(msg.sender, transactionId);
    executeTransaction(transactionId);
  }

  /**
   * @dev Returns the confirmation status of a transaction.
   * @param transactionId Transaction ID.
   */
  function isConfirmed(uint transactionId) public view returns (bool) {
    uint count = 0;
    mapping(address => bool) storage transactionConfirmations = confirmations[transactionId];

    uint256 signerCount = signers.length;
    for (uint i = 0; i < signerCount; ) {
      if (transactionConfirmations[signers[i]])
        count += 1;
      if (count == required)
        return true;
      
      unchecked {
        i++;
      }
    }
    return false;
  }

  /**
   * Web3 call functions
   *
   * @dev Returns number of confirmations of a transaction.
   * @param transactionId Transaction ID.
   */
  function getConfirmationCount(uint transactionId) public view returns (uint count) {
    mapping(address => bool) storage transactionConfirmations = confirmations[transactionId];

    uint256 signerCount = signers.length;
    for (uint i = 0; i < signerCount; ) {
      if (transactionConfirmations[signers[i]])
        count += 1;
      
      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Returns total number of transactions after filers are applied.
   * @param pending Include pending transactions.
   * @param executed Include executed transactions.
   */
  function getTransactionCount(bool pending, bool executed) public view returns (uint count) {
    for (uint i = 0; i < transactionCount; ) {
      if ((pending && !transactions[i].executed && !isTransactionTimedOut(i)) || (executed && transactions[i].executed))
        count += 1;

      unchecked {
        i++;
      }
    }
  }


  /**
   * @dev Returns array with signer addresses, which confirmed transaction.
   * @param transactionId Transaction ID.
   */
  function getConfirmations(uint transactionId) public view returns (address[] memory _confirmations) {
    uint256 signerCount = signers.length;
    address[] memory confirmationsTemp = new address[](signerCount);
    mapping(address => bool) storage transactionConfirmations = confirmations[transactionId];
    uint count = 0;
    uint i;
    
    for (i = 0; i < signerCount; ) {
      if (transactionConfirmations[signers[i]]) {
        confirmationsTemp[count] = signers[i];
        count += 1;
      }

      unchecked {
        i++;
      }
    }

    _confirmations = new address[](count);

    for (i = 0; i < count; ) {
      _confirmations[i] = confirmationsTemp[i];

      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Returns list of transaction IDs in defined range.
   * @param from Index start position of transaction array.
   * @param to Index end position of transaction array.
   * @param pending Include pending transactions.
   * @param executed Include executed transactions.
   */
  function getTransactionIds(uint from, uint to, bool pending, bool executed) public view returns (uint[] memory _transactionIds)
  {
    require(from < to, "Invalid range: from must be less than to");

    from = MathUpgradeable.min(from, transactionCount);
    to = MathUpgradeable.max(to, transactionCount);
    
    uint[] memory transactionIdsTemp = new uint[](to - from);
    uint count = 0;

    for (uint i = from; i < to; ) {
      if ((pending && !transactions[i].executed && !isTransactionTimedOut(i))
      || (executed && transactions[i].executed))
      {
        transactionIdsTemp[count] = i;
        count += 1;
      }

      unchecked {
        i++;
      }
    }

    _transactionIds = new uint[](count);

    for (uint i = 0; i < count; ) {
      _transactionIds[i] = transactionIdsTemp[i];

      unchecked {
        i++;
      }
    }
  }

  /**
    * @dev See {IERC721Receiver-onERC721Received}.
    *
    * Always returns `IERC721Receiver.onERC721Received.selector`.
    */
  function onERC721Received(
      address,
      address,
      uint256,
      bytes memory
  ) public virtual override returns (bytes4) {
      return this.onERC721Received.selector;
  }

  function onERC1155Received(
      address,
      address,
      uint256,
      uint256,
      bytes memory
  ) public virtual override returns (bytes4) {
      return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
      address,
      address,
      uint256[] memory,
      uint256[] memory,
      bytes memory
  ) public virtual override returns (bytes4) {
      return this.onERC1155BatchReceived.selector;
  }

  
  /**
   * Internal functions
   *
   * @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
   * @param destination Transaction target address.
   * @param value Transaction ether value.
   * @param data Transaction data payload.
   */
  function addTransaction(address payable destination, address token, TokenStandard ts, uint tokenId, uint value, bytes memory data, uint confirmTimestamp, uint txTimestamp) internal notNull(destination) returns (uint transactionId) {
    transactionId = transactionCount;
    transactions[transactionId] = Transaction({
      destination : destination,
      token: token,
      ts: ts,
      tokenId: tokenId,
      value : value,
      data : data,
      executed : false,
      confirmTimestamp : confirmTimestamp,
      txTimestamp : txTimestamp
      });
    transactionCount += 1;
    emit Submission(transactionId);
  }


  /**
   * @dev Allows anyone to execute a confirmed transaction.
   * @param transactionId Transaction ID.
   */
  function executeTransaction(uint transactionId) internal notExecuted(transactionId) {
    if (isConfirmed(transactionId)) {
      Transaction storage txn = transactions[transactionId];
      
      txn.executed = true;
      if(txn.ts == TokenStandard.USER) {
        require(address(this).balance >= txn.value, "not enough amount to withdraw");
        (bool transferSuccess,) =txn.destination.call{value: txn.value}(txn.data);
        if (transferSuccess)
          emit Execution(transactionId);
        else {
          emit ExecutionFailure(transactionId);
          txn.executed = false;
        }
      } else if(txn.ts == TokenStandard.ERC20) {
        IERC20Upgradeable(txn.token).safeTransfer(txn.destination, txn.value);
        emit Execution(transactionId);
      } else if(txn.ts == TokenStandard.ERC721) {
        IERC721Upgradeable(txn.token).safeTransferFrom(address(this), txn.destination, txn.tokenId);
        emit Execution(transactionId);
      } else if(txn.ts == TokenStandard.ERC1155) {
        IERC1155Upgradeable(txn.token).safeTransferFrom(address(this), txn.destination, txn.tokenId, txn.value, "");
        emit Execution(transactionId);
      }
    }
  }

  function isTransactionTimedOut(uint transactionId) internal view returns (bool) {
    Transaction storage transaction = transactions[transactionId];
    if(_getNow() < transaction.txTimestamp + transaction.confirmTimestamp || transaction.confirmTimestamp == 0) {
      return false;
    }
    return true;
  }

  function isSignerChangeConfirmed(address _newSigner) internal view returns (bool) {
    uint256 signerCount = signers.length;
    uint256 count;
    mapping(address => bool) storage confirmation = signerChangeConfirmations[_newSigner];

    for (uint i = 0; i < signerCount && count < required; ) {
      if (confirmation[signers[i]]) count ++;
      
      unchecked {
        i++;
      }
    }

    return count == required;
  }

  function removeSigner(address oldSigner) internal {
    if (!isSigner[oldSigner]) return;

    uint256 signerCount = signers.length;
    for (uint i = 0; i < signerCount; ) {
      if (signers[i] == oldSigner) {
          if (i != signerCount - 1) {
            signers[i] = signers[signerCount - 1];
          }
          signers.pop();
          isSigner[oldSigner] = false;
          break;
      }

      unchecked {
        i++;
      }
    }
  }

  function clearSignerChangeConfirmations(address _newSigner) internal {
    uint256 signerCount = signers.length;

    mapping(address => bool) storage confirmation = signerChangeConfirmations[_newSigner];

    for (uint i = 0; i < signerCount; ) {
        confirmation[signers[i]] = false;

        unchecked {
          i++;
        }
    }
  }

  function _getNow() internal view returns (uint256) {
      return block.timestamp;
  }

}
