// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./AbstractClientAccess.sol";
import "./IBatchStorage.sol";

abstract contract AbstractBatchStorage is IAbstractBatchStorage, AbstractClientAccess {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  /**
   * @notice BatchId => account => balance in batch
   */
  mapping(bytes32 => mapping(address => uint256)) public accountBalances;
  mapping(address => bytes32[]) public accountBatches;
  mapping(bytes32 => Batch) public batches;
  bytes32[] public batchIds;

  /**
   * @dev allowances of client => recipient => batchId => token => amount
   */
  mapping(address => mapping(address => mapping(bytes32 => mapping(address => uint256)))) public allowances;

  /* ========== CONSTRUCTOR ========== */
  constructor(IContractRegistry __contractRegistry, address _client)
    AbstractClientAccess(__contractRegistry, _client)
  {}

  /* ========== EVENTS ========== */
  /* ========== VIEWS ========== */

  function getBatch(bytes32 batchId) public view virtual returns (Batch memory) {
    return batches[batchId];
  }

  function getBatchType(bytes32 batchId) public view virtual override returns (BatchType) {
    return batches[batchId].batchType;
  }

  /**
   * @notice Get ids for all batches that a user has interacted with
   * @param _account The address for whom we want to retrieve batches
   */
  function getAccountBatches(address _account) external view virtual returns (bytes32[] memory) {
    return accountBatches[_account];
  }

  /**
   * @notice Get ids for all batches that a user has interacted with
   * @param _account The address for whom we want to retrieve batches
   */
  function getAccountBalance(bytes32 batchId, address _account) external view virtual returns (uint256) {
    return accountBalances[batchId][_account];
  }

  /* ========== MODIFIERS ========== */

  modifier onlyOwnerOf(bytes32 batchId) {
    _onlyClients();
    Batch storage batch = batches[batchId];
    require(
      batch.owner == msg.sender || delegates[batch.owner][msg.sender],
      "client does not have access to this batch"
    );
    _;
  }

  /* ========== ADMIN FUNCTIONS (CLIENT ONLY) ========== */

  function createBatch(BatchType _batchType, BatchTokens memory _tokens)
    external
    override(IAbstractBatchStorage)
    onlyClients
    returns (bytes32)
  {
    bytes32 _id = _generateId();
    batchIds.push(_id);
    Batch storage batch = batches[_id];
    batch.batchType = _batchType;
    batch.batchId = _id;
    batch.sourceToken = _tokens.sourceToken;
    batch.targetToken = _tokens.targetToken;
    batch.owner = msg.sender;
    return _id;
  }

  function deposit(
    bytes32 batchId,
    address owner,
    uint256 amount
  ) public override onlyOwnerOf(batchId) returns (uint256) {
    Batch storage batch = batches[batchId];
    // todo allow anyone to deposit to this batch, not just the client address
    return _deposit(batch, owner, amount, msg.sender);
  }

  function _deposit(
    Batch storage batch,
    address owner,
    uint256 amount,
    address sender
  ) internal returns (uint256) {
    require(!batch.claimable, "can't deposit");
    batch.sourceTokenBalance += amount;
    batch.unclaimedShares += amount;
    accountBalances[batch.batchId][owner] += amount;
    _cacheAccount(batch.batchId, owner);
    _transferFrom(batch.sourceToken, sender, address(this), amount);
    return amount;
  }

  /**
   * @notice This function checks all requirements for claiming, updates batches and balances and transfers tokens
   */

  function claim(
    bytes32 batchId,
    address owner,
    uint256 shares,
    address recipient
  ) public override onlyOwnerOf(batchId) returns (uint256, uint256) {
    Batch storage batch = batches[batchId];
    require(batch.claimable, "not yet claimable");

    uint256 claimAmount = shares == 0 ? accountBalances[batchId][owner] : shares;

    (uint256 claimableTokenBalance, uint256 claimAccountBalanceBefore, ) = previewClaim(batchId, owner, claimAmount);

    accountBalances[batchId][owner] -= claimAmount;
    batch.targetTokenBalance -= claimableTokenBalance;
    batch.unclaimedShares -= claimAmount;

    _transfer(batch.targetToken, owner, recipient, batchId, claimableTokenBalance);

    return (claimableTokenBalance, claimAccountBalanceBefore);
  }

  function previewClaim(
    bytes32 batchId,
    address owner,
    uint256 shares
  )
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Batch memory batch = batches[batchId];
    uint256 claimAccountBalanceBefore = accountBalances[batchId][owner];

    require(shares <= batch.unclaimedShares && shares <= claimAccountBalanceBefore, "insufficient balance");

    uint256 targetTokenBalance = (batch.targetTokenBalance * shares) / batch.unclaimedShares;

    return (targetTokenBalance, claimAccountBalanceBefore, claimAccountBalanceBefore - shares);
  }

  /**
   * @notice Moves funds from unclaimed batches into the current mint/redeem batch
   * @param _sourceBatch the id of the claimable batch
   * @param _destinationBatch the id of the redeem batch
   * @param owner owner of the account balance
   * @param shares how many shares should be claimed
   */
  function moveUnclaimedIntoCurrentBatch(
    bytes32 _sourceBatch,
    bytes32 _destinationBatch,
    address owner,
    uint256 shares
  ) external override onlyOwnerOf(_sourceBatch) onlyOwnerOf(_destinationBatch) returns (uint256) {
    Batch storage sourceBatch = batches[_sourceBatch];
    Batch storage destinationBatch = batches[_destinationBatch];

    require(sourceBatch.claimable, "not yet claimable");
    require(sourceBatch.batchType != destinationBatch.batchType, "incorrect batchType");
    require(sourceBatch.targetToken == destinationBatch.sourceToken, "tokens don't match");

    (uint256 targetTokenBalance, ) = claim(_sourceBatch, owner, shares, address(0));
    return _deposit(destinationBatch, owner, targetTokenBalance, address(0));
  }

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param batchId From which batch should funds be withdrawn from
   * @param owner address that owns the account balance
   * @param amount amount of tokens to withdraw from batch
   * @param recipient address that will receive the token transfer. if address(0) then no transfer is made
   */
  function withdraw(
    bytes32 batchId,
    address owner,
    uint256 amount,
    address recipient
  ) public override onlyOwnerOf(batchId) returns (uint256) {
    // todo make this public so account owners can withdraw
    Batch storage batch = batches[batchId];
    require(accountBalances[batchId][owner] >= amount);
    require(batch.claimable == false, "already processed");

    //At this point the account balance is equal to the supplied token and can be used interchangeably
    accountBalances[batchId][owner] -= amount;
    batch.sourceTokenBalance -= amount;
    batch.unclaimedShares -= amount;

    _transfer(batch.sourceToken, owner, recipient, batchId, amount);
    return (amount);
  }

  /**
   * @notice approve allows the client contract to approve an address to be the recipient of a withdrawal or claim
   */
  function approve(
    IERC20 token,
    address delegatee,
    bytes32 batchId,
    uint256 amount
  ) external override(IAbstractBatchStorage) onlyOwnerOf(batchId) {
    allowances[msg.sender][delegatee][batchId][address(token)] = amount;
  }

  /**
   * @notice This function transfers the batch source tokens to the client usually for a minting or redeming operation
   * @param batchId From which batch should funds be withdrawn from
   */
  function withdrawSourceTokenFromBatch(bytes32 batchId)
    public
    override(IAbstractBatchStorage)
    onlyOwnerOf(batchId)
    returns (uint256)
  {
    Batch storage batch = batches[batchId];
    require(!batch.claimable, "already processed");
    batch.sourceToken.safeTransfer(msg.sender, batch.sourceTokenBalance);
    return (batch.sourceTokenBalance);
  }

  function depositTargetTokensIntoBatch(bytes32 batchId, uint256 amount)
    external
    override(IAbstractBatchStorage)
    onlyOwnerOf(batchId)
    returns (bool)
  {
    Batch storage batch = batches[batchId];
    require(!batch.claimable, "deposit already made"); // todo allow multiple deposits

    batch.targetToken.safeTransferFrom(msg.sender, address(this), amount);

    batch.claimable = true;
    batch.targetTokenBalance += amount;

    return true;
  }

  /* ========== INTERNAL ========== */

  /**
   * todo `clients` ultimately may withdraw tokens for a batch they create at anytime by calling withdrawSourceTokenFromBatch. tokens may be transfered out of this contract if the given recipient is a registered client or if the client has granted an allowance to a recipient to receive tokens. this means that in order to trust this contract, you must look at the clients because they can give themselves infinite allowance as a recipient of a target token from this contract. simply put, a rogue contract may infinite approve everything held by the contract and potentially send to itself.  any new client to this contract must be reviewed to ensure it does not make a claim or withdrawal for an address for which it should not. thought was given to designing this in a way to offer permissionless batch logic for any client, but greater attention would need to be given to scopes and boundaries. consider apodoting eip-1155 / eip-4626  standard interfaces for greater interoperability
   */
  function _transfer(
    IERC20 token,
    address owner,
    address recipient,
    bytes32 batchId,
    uint256 amount
  ) internal {
    if (recipient != address(0)) {
      Batch memory batch = batches[batchId];
      uint256 allowance = allowances[msg.sender][recipient][batchId][address(token)];
      bool hasAllowance = allowance >= amount;

      require(
        recipient == owner || hasAllowance || recipient == batch.owner || delegates[batch.owner][recipient],
        "won't send"
      );

      if (hasAllowance && allowance != 0) {
        allowances[msg.sender][recipient][batchId][address(token)] -= amount;
      }

      token.safeTransfer(recipient, amount);
    }
  }

  function _transferFrom(
    IERC20 token,
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    if (sender != address(0) && recipient != address(0)) {
      token.safeTransferFrom(sender, recipient, amount);
    }
  }

  function _cacheAccount(bytes32 _id, address _owner) internal {
    //Save the batchId for the user so they can be retrieved to claim the batch
    if (accountBatches[_owner].length == 0 || accountBatches[_owner][accountBatches[_owner].length - 1] != _id) {
      accountBatches[_owner].push(_id);
    }
  }

  /**
   * @notice Generates the next batch id hashing the last batchId and timestamp
   */
  function _generateId() private view returns (bytes32) {
    bytes32 previousBatchId = batchIds.length > 0 ? batchIds[batchIds.length - 1] : bytes32("");
    return keccak256(abi.encodePacked(block.timestamp, previousBatchId));
  }
}
