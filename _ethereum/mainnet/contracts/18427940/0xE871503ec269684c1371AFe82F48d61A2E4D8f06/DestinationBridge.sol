/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "./IAxelarGateway.sol";
import "./AxelarExecutable.sol";
import "./IRWALike.sol";
import "./IAllowlist.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./MintRateLimiter.sol";
import "./SafeERC20.sol";

contract DestinationBridge is
  AxelarExecutable,
  MintTimeBasedRateLimiter,
  Ownable,
  Pausable
{
  using SafeERC20 for IERC20;
  /// @notice Token contract bridged by this contract
  IRWALike public immutable TOKEN;

  /// @notice Pointer to AxelarGateway contract
  IAxelarGateway public immutable AXELAR_GATEWAY;

  /// @notice Pointer to USDY allowlist
  IAllowlist public immutable ALLOWLIST;

  // Mapping used to track approvers, approved msg src's and spent nonces
  mapping(address => bool) public approvers;
  mapping(string => bytes32) public chainToApprovedSender;
  mapping(bytes32 => mapping(uint256 => bool)) public isSpentNonce;

  /// @notice Versioning for payload, must match SourceBridge version
  bytes32 public constant VERSION = "1.0";

  /// @notice Mappings used to track transaction and thresholds
  mapping(bytes32 => TxnThreshold) public txnToThresholdSet;
  mapping(string => Threshold[]) public chainToThresholds;
  mapping(bytes32 => Transaction) public txnHashToTransaction;

  constructor(
    address _token,
    address _axelarGateway,
    address _allowlist,
    address _ondoApprover,
    address _owner,
    uint256 _mintLimit,
    uint256 _mintDuration
  )
    AxelarExecutable(_axelarGateway)
    MintTimeBasedRateLimiter(_mintDuration, _mintLimit)
  {
    TOKEN = IRWALike(_token);
    AXELAR_GATEWAY = IAxelarGateway(_axelarGateway);
    ALLOWLIST = IAllowlist(_allowlist);
    approvers[_ondoApprover] = true;
    _transferOwnership(_owner);
  }

  /*//////////////////////////////////////////////////////////////
                         Axelar Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Internal overriden function that is executed when contract is called by Axelar Relayer
   *
   * @param srcChain The string of the source chain eg: arbitrum
   * @param srcAddr  The string of the address of the source contract
   * @param payload  The payload to pass cross chain
   */
  function _execute(
    string calldata srcChain,
    string calldata srcAddr,
    bytes calldata payload
  ) internal override whenNotPaused {
    (bytes32 version, , address srcSender, uint256 amt, uint256 nonce) = abi
      .decode(payload, (bytes32, uint256, address, uint256, uint256));

    if (version != VERSION) {
      revert InvalidVersion();
    }
    if (chainToApprovedSender[srcChain] == bytes32(0)) {
      revert ChainNotSupported();
    }
    if (chainToApprovedSender[srcChain] != keccak256(abi.encode(srcAddr))) {
      revert SourceNotSupported();
    }
    if (isSpentNonce[chainToApprovedSender[srcChain]][nonce]) {
      revert NonceSpent();
    }

    isSpentNonce[chainToApprovedSender[srcChain]][nonce] = true;

    bytes32 txnHash = keccak256(payload);
    txnHashToTransaction[txnHash] = Transaction(srcSender, amt);
    _attachThreshold(amt, txnHash, srcChain);
    _approve(txnHash);
    _mintIfThresholdMet(txnHash);
    emit MessageReceived(txnHash, srcChain, srcSender, amt, nonce);
  }

  /*//////////////////////////////////////////////////////////////
                        Internal Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Internal function used to attach a specific threshold to a given
   *         `txnHash`.
   *
   * @param amount   The amount of the token being bridged
   * @param txnHash  The transaction hash to associate the threshold with
   * @param srcChain The chain corresponding to the chain that the token
   *                 being bridged originated from.
   */
  function _attachThreshold(
    uint256 amount,
    bytes32 txnHash,
    string memory srcChain
  ) internal {
    Threshold[] memory thresholds = chainToThresholds[srcChain];
    for (uint256 i = 0; i < thresholds.length; ++i) {
      Threshold memory t = thresholds[i];
      if (amount <= t.amount) {
        txnToThresholdSet[txnHash] = TxnThreshold(
          t.numberOfApprovalsNeeded,
          new address[](0)
        );
        break;
      }
    }
    if (txnToThresholdSet[txnHash].numberOfApprovalsNeeded == 0) {
      revert NoThresholdMatch();
    }
  }

  /**
   * @notice Internal function used to approve and conditionally mint for a
   *         given txn. Approval is conditional on this approver having not
   *         previously approved the txn
   *
   * @param txnHash The txnHash to approve and conditionally mint to
   */
  function _approve(bytes32 txnHash) internal {
    // Check that the approver has not already approved
    TxnThreshold storage t = txnToThresholdSet[txnHash];
    uint256 approversLength = t.approvers.length;
    if (approversLength > 0) {
      for (uint256 i = 0; i < approversLength; ++i) {
        if (t.approvers[i] == msg.sender) {
          revert AlreadyApproved();
        }
      }
    }
    t.approvers.push(msg.sender);
    emit TransactionApproved(
      txnHash,
      msg.sender,
      approversLength + 1,
      t.numberOfApprovalsNeeded
    );
  }

  /**
   * @notice Internal function to mint tokens for a user if the transaction has
   *         passed the threshold for number of approvers
   *
   * @param txnHash The hash of the payload we wish to mint
   */
  function _mintIfThresholdMet(bytes32 txnHash) internal {
    bool thresholdMet = _checkThresholdMet(txnHash);
    if (thresholdMet) {
      Transaction memory txn = txnHashToTransaction[txnHash];
      _checkAndUpdateInstantMintLimit(txn.amount);
      if (
        address(ALLOWLIST) != address(0) && !ALLOWLIST.isAllowed(txn.sender)
      ) {
        ALLOWLIST.setAccountStatus(
          txn.sender,
          ALLOWLIST.getValidTermIndexes()[0],
          true
        );
      }
      TOKEN.mint(txn.sender, txn.amount);
      // Clear the approval for this bridge payload
      delete txnHashToTransaction[txnHash];
      emit BridgeCompleted(txn.sender, txn.amount);
    }
  }

  /**
   * @notice Internal function used to check if the approval threshold has been
   *         met for a given transaction.
   *
   * @param txnHash The txnHash to check
   *
   * @dev If an approver has been removed, any previous approvals are still valid
   */
  function _checkThresholdMet(bytes32 txnHash) internal view returns (bool) {
    TxnThreshold storage t = txnToThresholdSet[txnHash];
    return t.approvers.length >= t.numberOfApprovalsNeeded;
  }

  /*//////////////////////////////////////////////////////////////
                        Protected Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Protected Function used to approve messages passed to the
   *         Receiver contract. This function is able to be called by any
   *         approver that is added and associated with Ondo.
   *
   * @param txnHash The keccak256 hash of the payload
   */
  function approve(bytes32 txnHash) external {
    if (!approvers[msg.sender]) {
      revert NotApprover();
    }
    _approve(txnHash);
    _mintIfThresholdMet(txnHash);
  }

  /**
   * @notice Admin function to add an ondo Signer or Axelar Relayer
   *
   * @param approver  The address we would like to add
   */
  function addApprover(address approver) external onlyOwner {
    approvers[approver] = true;
    emit ApproverAdded(approver);
  }

  /**
   * @notice Admin function to remove an approver
   *
   * @param approver The address of the approver that we would like to remove
   */
  function removeApprover(address approver) external onlyOwner {
    delete approvers[approver];
    emit ApproverRemoved(approver);
  }

  /**
   * @notice Admin function that will allow bridge calls originating from a given address
   *         on a given chain.
   * @notice This will initialize a nested mapping in which spent nonces from this `srcAddress`
   *         are logged and prevented from being reused
   *
   * @param srcChain            The chain to support
   * @param srcContractAddress  The address of the Ondo Bridge on the source chain
   *
   * @dev srcContractAddress: Is case sensitive and must be the checksum address
   * of the srcBridge contract which is allowed to call into this contract.
   */
  function addChainSupport(
    string calldata srcChain,
    string calldata srcContractAddress
  ) external onlyOwner {
    chainToApprovedSender[srcChain] = keccak256(abi.encode(srcContractAddress));
    emit ChainIdSupported(srcChain, srcContractAddress);
  }

  /**
   * @notice Admin function that will remove support for previously supported chains
   *
   * @param srcChain The source chain whose support is being removed
   */
  function removeChainSupport(string calldata srcChain) external onlyOwner {
    delete chainToApprovedSender[srcChain];
    emit ChainSupportRemoved(srcChain);
  }

  /**
   * @notice Admin function used to clear and set thresholds corresponding to a chain
   *
   * @param srcChain       The chain to set the threshold for
   * @param amounts        The ordered array of values corresponding to
   *                       the amount for a given threshold
   * @param numOfApprovers The ordered array of the number of approvals needed
   *                       for a given threshold
   *
   * @dev This function will remove all previously set thresholds for a given chain
   *      and will thresholds corresponding to the params of this function. Passing
   *      in empty arrays will remove all thresholds for a given chain
   */
  function setThresholds(
    string calldata srcChain,
    uint256[] calldata amounts,
    uint256[] calldata numOfApprovers
  ) external onlyOwner {
    if (amounts.length != numOfApprovers.length) {
      revert ArrayLengthMismatch();
    }
    delete chainToThresholds[srcChain];
    for (uint256 i = 0; i < amounts.length; ++i) {
      if (numOfApprovers[i] == 0) {
        revert NumOfApproversCannotBeZero();
      }
      if (i == 0) {
        chainToThresholds[srcChain].push(
          Threshold(amounts[i], numOfApprovers[i])
        );
      } else {
        if (chainToThresholds[srcChain][i - 1].amount > amounts[i]) {
          revert ThresholdsNotInAscendingOrder();
        }
        chainToThresholds[srcChain].push(
          Threshold(amounts[i], numOfApprovers[i])
        );
      }
    }
    emit ThresholdSet(srcChain, amounts, numOfApprovers);
  }

  /**
   * @notice Admin function used to set the mint limit
   *
   * @param mintLimit The new mint limit
   */
  function setMintLimit(uint256 mintLimit) external onlyOwner {
    _setMintLimit(mintLimit);
  }

  /**
   * @notice Admin function used to set the mint duration
   *
   * @param mintDuration The new mint duration
   */
  function setMintLimitDuration(uint256 mintDuration) external onlyOwner {
    _setMintLimitDuration(mintDuration);
  }

  /**
   * @notice Admin function used to pause the contract
   *
   * @dev Only used for bridge functions
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Admin function used to unpause the contract
   *
   * @dev Only used for bridge functions
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Admin function used to rescue ERC20 Tokens sent to the contract
   *
   * @param _token The address of the token to rescue
   */
  function rescueTokens(address _token) external onlyOwner {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(owner(), balance);
  }

  /*//////////////////////////////////////////////////////////////
                       Helper Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice External view function used to get the number of approvers for a
   *         given txnHash
   *
   * @param txnHash The hash to get the number of approvers for
   */
  function getNumApproved(bytes32 txnHash) external view returns (uint256) {
    return txnToThresholdSet[txnHash].approvers.length;
  }

  /*//////////////////////////////////////////////////////////////
                      Structs, Events, Errors
  //////////////////////////////////////////////////////////////*/

  struct Threshold {
    uint256 amount;
    uint256 numberOfApprovalsNeeded;
  }

  struct TxnThreshold {
    uint256 numberOfApprovalsNeeded;
    address[] approvers;
  }

  struct Transaction {
    address sender;
    uint256 amount;
  }

  /**
   * @notice event emitted when an address is removed as an approver
   *
   * @param approver The address being removed
   */
  event ApproverRemoved(address approver);

  /**
   * @notice event emitted when an address is added as an approver
   *
   * @param approver  The address to add
   */
  event ApproverAdded(address approver);

  /**
   * @notice event emitted when a new contract is whitelisted as an approved
   *         message passer.
   *
   * @param srcChain        The chain for the approved address
   * @param approvedSource  The address corresponding to the source bridge contract
   */
  event ChainIdSupported(string indexed srcChain, string approvedSource);

  /**
   * @notice event emitted when a threshold has been set
   *
   * @param chain           The chain for which the threshold was set
   * @param amounts         The amount of tokens to reach this threshold
   * @param numOfApprovers  The number of approvals needed
   */
  event ThresholdSet(
    string indexed chain,
    uint256[] amounts,
    uint256[] numOfApprovers
  );

  /**
   * @notice event emitted when the user has been minted their tokens on the dst chain
   *
   * @param user    The recipient address of the newly minted tokens
   * @param amount  The amount of tokens that have been minted
   */
  event BridgeCompleted(address indexed user, uint256 amount);

  /**
   * @notice event emitted when this bridge contract receives a cross chain message
   *
   * @param txnHash   The hash of the payload that has been bridged
   * @param srcChain  The chain from which the message is originating
   * @param srcSender The address of the msg.sender on the source chain
   * @param amt       The amount of tokens being bridged
   * @param nonce     The nonce corresponding to the contract which originated the msg
   */
  event MessageReceived(
    bytes32 indexed txnHash,
    string indexed srcChain,
    address indexed srcSender,
    uint256 amt,
    uint256 nonce
  );

  /**
   * @notice event emitted when a transaction has been approved
   *
   * @param txnHash              The hash of the payload that has been approved
   * @param approver             The address of the approver
   * @param numApprovers         The number of approvers for this transaction
   * @param thresholdRequirement The number of approvals needed for this transaction
   */
  event TransactionApproved(
    bytes32 indexed txnHash,
    address approver,
    uint256 numApprovers,
    uint256 thresholdRequirement
  );

  /**
   * @notice event emitted when support for a chain is removed
   *
   * @param srcChain The chain whose support is being removed
   */
  event ChainSupportRemoved(string indexed srcChain);

  error NotApprover();
  error NoThresholdMatch();
  error ThresholdsNotInAscendingOrder();

  error ChainNotSupported();
  error SourceNotSupported();
  error NonceSpent();
  error AlreadyApproved();
  error InvalidVersion();
  error ArrayLengthMismatch();
  error NumOfApproversCannotBeZero();
}
