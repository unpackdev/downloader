// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./IBatchStorage.sol";
import "./ACLAuth.sol";
import "./IStaking.sol";
import "./AbstractFee.sol";
import "./AbstractSweethearts.sol";
import "./AbstractViewableBatchStorage.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ThreeXBatchVault.sol";

abstract contract AbstractBatchController is
  ACLAuth,
  Pausable,
  ReentrancyGuard,
  AbstractFee,
  AbstractViewableBatchStorage
{
  using SafeERC20 for IERC20;

  struct ProcessingThreshold {
    uint256 batchCooldown;
    uint256 mintThreshold;
    uint256 redeemThreshold;
  }

  struct Slippage {
    uint256 mintBps; // in bps
    uint256 redeemBps; // in bps
  }

  IStaking public staking;
  Slippage public slippage;

  ProcessingThreshold public processingThreshold;

  uint256 public lastMintedAt;
  uint256 public lastRedeemedAt;
  bytes32 public currentMintBatchId;
  bytes32 public currentRedeemBatchId;

  BatchTokens public redeemBatchTokens;
  BatchTokens public mintBatchTokens;

  /* ========== EVENTS ========== */

  event ProcessingThresholdUpdated(ProcessingThreshold prevThreshold, ProcessingThreshold newTreshold);
  event SlippageUpdated(Slippage prev, Slippage current);
  event StakingUpdated(address beforeAddress, address afterAddress);

  // todo move these events to the BatchStorage layer
  event WithdrawnFromBatch(bytes32 batchId, uint256 amount, address indexed to);
  event Claimed(address indexed account, BatchType batchType, uint256 shares, uint256 claimedToken);
  event Deposit(address indexed from, uint256 deposit);
  event DepositedUnclaimedSetTokenForRedeem(uint256 amount, address indexed account);
  event Withdrawal(address indexed to, uint256 amount);

  constructor(IContractRegistry __contractRegistry) AbstractViewableBatchStorage() {}

  /* ========== ADMIN ========== */

  /**
   * @notice sets batch storage contract
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function setBatchStorage(AbstractBatchStorage _address) external onlyRoles(DAO_ROLE, GUARDIAN_ROLE) {
    batchStorage = _address;
    if (currentMintBatchId == "") {
      _createBatch(BatchType.Mint);
    }
    if (currentRedeemBatchId == "") {
      _createBatch(BatchType.Redeem);
    }
  }

  /**
   * @notice Pauses the contract.
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function pause() external onlyRoles(DAO_ROLE, GUARDIAN_ROLE) {
    _pause();
  }

  /**
   * @notice Unpauses the contract.
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function unpause() external onlyRoles(DAO_ROLE, GUARDIAN_ROLE) {
    _unpause();
  }

  /**
   * @notice will grant access to the batchStorage contract as well as batches owned by this address
   **/
  function grantClientAccess(address newClient) external onlyRoles(DAO_ROLE, GUARDIAN_ROLE) {
    batchStorage.grantClientAccess(newClient);
  }

  /**
   * @notice will accept access to the batchStorage contract as well as batches owned by this address
   **/
  function acceptClientAccess(address owner) external onlyRoles(DAO_ROLE, GUARDIAN_ROLE) {
    batchStorage.acceptClientAccess(owner);
  }

  /**
   * @notice Updates the staking contract
   */
  function setStaking(address _staking) external onlyRoles(DAO_ROLE, GUARDIAN_ROLE) {
    emit StakingUpdated(address(staking), _staking);
    staking = IStaking(_staking);
  }

  function _createBatch(BatchType _batchType) internal returns (bytes32) {
    bytes32 id;
    if (BatchType.Mint == _batchType) {
      id = batchStorage.createBatch(BatchType.Mint, mintBatchTokens);
      currentMintBatchId = id;
    }

    if (BatchType.Redeem == _batchType) {
      id = batchStorage.createBatch(BatchType.Redeem, redeemBatchTokens);
      currentRedeemBatchId = id;
    }

    return id;
  }

  /**
   * @notice sets slippage for mint and redeem
   * @param _mintSlippage amount in bps (e.g. 50 = 0.5%)
   * @param _redeemSlippage amount in bps (e.g. 50 = 0.5%)
   */
  function setSlippage(uint256 _mintSlippage, uint256 _redeemSlippage) external onlyRoles(DAO_ROLE, GUARDIAN_ROLE) {
    Slippage memory newSlippage = Slippage({ mintBps: _mintSlippage, redeemBps: _redeemSlippage });
    emit SlippageUpdated(slippage, newSlippage);
    slippage = newSlippage;
  }

  /**
   * @notice Changes the the ProcessingThreshold
   * @param _cooldown Cooldown in seconds
   * @param _mintThreshold Amount of MIM necessary to mint immediately
   * @param _redeemThreshold Amount of 3X necessary to mint immediately
   * @dev The cooldown is the same for redeem and mint batches
   */
  function setProcessingThreshold(
    uint256 _cooldown,
    uint256 _mintThreshold,
    uint256 _redeemThreshold
  ) external onlyRoles(DAO_ROLE, GUARDIAN_ROLE) {
    ProcessingThreshold memory newProcessingThreshold = ProcessingThreshold({
      batchCooldown: _cooldown,
      mintThreshold: _mintThreshold,
      redeemThreshold: _redeemThreshold
    });
    emit ProcessingThresholdUpdated(processingThreshold, newProcessingThreshold);
    processingThreshold = newProcessingThreshold;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Deposits funds in the current mint batch
   * @param amount Amount of DAI to use for minting
   * @param depositFor User that gets the shares attributed to (for use in zapper contract)
   */
  function depositForMint(uint256 amount, address depositFor)
    external
    nonReentrant
    whenNotPaused
    onlyApprovedContractOrEOA
  {
    mintBatchTokens.sourceToken.safeTransferFrom(msg.sender, address(this), amount);
    _deposit(amount, currentMintBatchId, depositFor);
  }

  /**
   * @notice deposits funds in the current redeem batch
   * @param amount amount of 3X to be redeemed
   */
  function depositForRedeem(uint256 amount) external nonReentrant whenNotPaused onlyApprovedContractOrEOA {
    redeemBatchTokens.sourceToken.safeTransferFrom(msg.sender, address(this), amount);
    _deposit(amount, currentRedeemBatchId, msg.sender);
  }

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param _batchId From which batch should funds be withdrawn from
   * @param _amountToWithdraw Amount of 3X or DAI to be withdrawn from the queue (depending on mintBatch / redeemBatch)
   * @param _withdrawFor User that gets the shares attributed to (for use in zapper contract)
   */
  function withdrawFromBatch(
    bytes32 _batchId,
    uint256 _amountToWithdraw,
    address _withdrawFor,
    address _recipient
  ) external returns (uint256) {
    return _withdrawFromBatch(_batchId, _amountToWithdraw, _withdrawFor, _recipient);
  }

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param _batchId From which batch should funds be withdrawn from
   * @param _amountToWithdraw Amount of 3X or DAI to be withdrawn from the queue (depending on mintBatch / redeemBatch)
   * @param _withdrawFor User that gets the shares attributed to (for use in zapper contract)
   */
  function withdrawFromBatch(
    bytes32 _batchId,
    uint256 _amountToWithdraw,
    address _withdrawFor
  ) external returns (uint256) {
    return _withdrawFromBatch(_batchId, _amountToWithdraw, _withdrawFor, _withdrawFor);
  }

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param batchId From which batch should funds be withdrawn from
   * @param amountToWithdraw Amount of 3X or DAI to be withdrawn from the queue (depending on mintBatch / redeemBatch)
   * @param withdrawFor User that gets the shares attributed to (for use in zapper contract)
   * @param recipient address that receives the withdrawn tokens
   */
  function _withdrawFromBatch(
    bytes32 batchId,
    uint256 amountToWithdraw,
    address withdrawFor,
    address recipient
  ) internal returns (uint256) {
    require(
      _hasRole(keccak256("ThreeXZapper"), msg.sender) || msg.sender == withdrawFor,
      "you cant transfer other funds"
    );

    if (msg.sender != withdrawFor) {
      // let's approve zapper contract to be a recipient of the withdrawal
      batchStorage.approve(batchStorage.getBatch(batchId).sourceToken, msg.sender, batchId, amountToWithdraw);
    }

    uint256 withdrawnAmount = batchStorage.withdraw(batchId, withdrawFor, amountToWithdraw, recipient);
    emit WithdrawnFromBatch(batchId, withdrawnAmount, withdrawFor);
    return withdrawnAmount;
  }

  /**
   * @notice Claims BTR after batch has been processed and stakes it in Staking.sol
   * @param _batchId Id of batch to claim from
   */
  function claimAndStake(bytes32 _batchId) external {
    claimForAndStake(_batchId, msg.sender);
  }

  function claimForAndStake(bytes32 _batchId, address _claimFor) public {
    (address recipient, BatchType batchType, uint256 accountBalance, uint256 tokenAmountClaimed, ) = _claim(
      _batchId,
      _claimFor,
      address(this)
    );

    require(batchType == BatchType.Mint, "wrong batch type");

    emit Claimed(recipient, batchType, accountBalance, tokenAmountClaimed);

    staking.stakeFor(tokenAmountClaimed, _claimFor);
  }

  /**
   * @notice Claims funds after the batch has been processed (get 3X from a mint batch and DAI from a redeem batch)
   * @param batchId Id of batch to claim from
   * @param _claimFor User that gets the shares attributed to (for use in zapper contract)
   */
  function claim(bytes32 batchId, address _claimFor) external returns (uint256) {
    (address recipient, BatchType batchType, uint256 accountBalance, uint256 tokenAmountToClaim, ) = _claim(
      batchId,
      _claimFor,
      address(this)
    );

    emit Claimed(recipient, batchType, accountBalance, tokenAmountToClaim);

    this.getBatch(batchId).targetToken.safeTransfer(recipient, tokenAmountToClaim);

    return tokenAmountToClaim;
  }

  /**
   * @notice This function checks all requirements for claiming, updates batches and balances and returns the values needed for the final transfer of tokens
   * @param batchId Id of batch to claim from
   * @param claimFor User that gets the shares attributed to (for use in zapper contract)
   * @param recipient where token is transfered to
   */
  function _claim(
    bytes32 batchId,
    address claimFor,
    address recipient
  )
    internal
    returns (
      address,
      BatchType,
      uint256,
      uint256,
      Batch memory
    )
  {
    require(_hasRole(keccak256("ThreeXZapper"), msg.sender) || msg.sender == claimFor, "you cant transfer other funds");

    Batch memory batch = batchStorage.getBatch(batchId);
    // todo try replacing batchId with batch to avoid having to lookup the batch again in dependent functions

    if (msg.sender != claimFor) {
      // let's approve zapper contract to be a recipient of the withdrawal
      (uint256 claimableTokenBalance, , ) = batchStorage.previewClaim(
        batchId,
        claimFor,
        batchStorage.getAccountBalance(batchId, claimFor)
      );

      batchStorage.approve(batch.targetToken, msg.sender, batchId, claimableTokenBalance);
    }

    (uint256 tokenAmountToClaim, uint256 accountBalanceBefore) = batchStorage.claim(batchId, claimFor, 0, recipient);

    return (msg.sender, batch.batchType, accountBalanceBefore, tokenAmountToClaim, batch);
  }

  /**
   * @notice Moves funds from unclaimed batches into the current mint/redeem batch
   * @param batchIds the ids of each batch where targetToken should be moved from
   * @param shares how many shares should be claimed in each of the batches
   * @param mint should move token into the currentMintBatch vs currentRedeemBatch
   * @dev Since our output token is not the same as our input token we would need to swap the output token via 2 hops into out input token.
          If we want to do so id prefer to create a second function to do so as it would also require a slippage parameter and the swapping logic
   */
  function moveUnclaimedIntoCurrentBatch(
    bytes32[] calldata batchIds,
    uint256[] calldata shares,
    bool mint
  ) external whenNotPaused {
    require(batchIds.length == shares.length, "array lengths must match");

    uint256 totalAmount;
    for (uint256 i; i < batchIds.length; i++) {
      totalAmount += batchStorage.moveUnclaimedIntoCurrentBatch(
        batchIds[i],
        mint ? currentMintBatchId : currentRedeemBatchId,
        msg.sender,
        shares[i]
      );
    }
    emit DepositedUnclaimedSetTokenForRedeem(totalAmount, msg.sender);
  }

  /**
   * @notice Deposit either 3X or DAI in their respective batches
   * @param _amount The amount of DAI or 3X a user is depositing
   * @param _batchId The current reedem or mint batch id to place the funds in the next batch to be processed
   * @param _depositFor User that gets the shares attributed to (for use in zapper contract)
   * @dev This function will be called by depositForMint or depositForRedeem and simply reduces code duplication
   */
  function _deposit(
    uint256 _amount,
    bytes32 _batchId,
    address _depositFor
  ) internal {
    batchStorage.deposit(_batchId, _depositFor, _amount);
    emit Deposit(_depositFor, _amount);
  }
}
