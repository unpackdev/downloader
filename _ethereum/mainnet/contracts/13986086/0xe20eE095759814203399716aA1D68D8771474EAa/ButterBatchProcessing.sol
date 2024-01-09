// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./YearnVault.sol";
import "./BasicIssuanceModule.sol";
import "./ISetToken.sol";
import "./CurveContracts.sol";
import "./IACLRegistry.sol";
import "./IContractRegistry.sol";
import "./IStaking.sol";
import "./IKeeperIncentive.sol";

/*
 * @notice This Contract allows smaller depositors to mint and redeem Butter (formerly known as HYSI) without needing to through all the steps necessary on their own,
 * which not only takes long but mainly costs enormous amounts of gas.
 * The Butter is created from several different yTokens which in turn need each a deposit of a crvLPToken.
 * This means multiple approvals and deposits are necessary to mint one Butter.
 * We batch this process and allow users to pool their funds. Then we pay a keeper to mint or redeem Butter regularly.
 */
contract ButterBatchProcessing is Pausable, ReentrancyGuard {
  using SafeERC20 for YearnVault;
  using SafeERC20 for ISetToken;
  using SafeERC20 for IERC20;

  /**
   * @notice Defines if the Batch will mint or redeem Butter
   */
  enum BatchType {
    Mint,
    Redeem
  }

  /**
   * @notice Defines if the Batch will mint or redeem Butter
   * @param curveMetaPool A CurveMetaPool for trading an exotic stablecoin against 3CRV
   * @param crvLPToken The LP-Token of the CurveMetapool
   */
  struct CurvePoolTokenPair {
    CurveMetapool curveMetaPool;
    IERC20 crvLPToken;
  }

  /**
   * @notice The Batch structure is used both for Batches of Minting and Redeeming
   * @param batchType Determines if this Batch is for Minting or Redeeming Butter
   * @param batchId bytes32 id of the batch
   * @param claimable Shows if a batch has been processed and is ready to be claimed, the suppliedToken cant be withdrawn if a batch is claimable
   * @param unclaimedShares The total amount of unclaimed shares in this batch
   * @param suppliedTokenBalance The total amount of deposited token (either 3CRV or Butter)
   * @param claimableTokenBalance The total amount of claimable token (either 3CRV or Butter)
   * @param tokenAddress The address of the the token to be claimed
   * @param shareBalance The individual share balance per user that has deposited token
   */
  struct Batch {
    BatchType batchType;
    bytes32 batchId;
    bool claimable;
    uint256 unclaimedShares;
    uint256 suppliedTokenBalance;
    uint256 claimableTokenBalance;
    address suppliedTokenAddress;
    address claimableTokenAddress;
  }

  /* ========== STATE VARIABLES ========== */

  bytes32 public immutable contractName = "ButterBatchProcessing";

  IContractRegistry public contractRegistry;
  IStaking public staking;
  ISetToken public setToken;
  IERC20 public threeCrv;
  CurveMetapool public threePool;
  BasicIssuanceModule public setBasicIssuanceModule;
  mapping(address => CurvePoolTokenPair) public curvePoolTokenPairs;

  /**
   * @notice This maps batch ids to addresses with share balances
   */
  mapping(bytes32 => mapping(address => uint256)) public accountBalances;
  mapping(address => bytes32[]) public accountBatches;
  mapping(bytes32 => Batch) public batches;
  bytes32[] public batchIds;

  uint256 public lastMintedAt;
  uint256 public lastRedeemedAt;
  bytes32 public currentMintBatchId;
  bytes32 public currentRedeemBatchId;
  uint256 public batchCooldown;
  uint256 public mintThreshold;
  uint256 public redeemThreshold;
  uint256 public mintSlippage = 7; // in bps
  uint256 public redeemSlippage = 7; // in bps
  uint256 public redemptionFees;
  uint256 public redemptionFeeRate;
  address public feeRecipient;

  mapping(address => bool) public sweethearts;

  /* ========== EVENTS ========== */

  event Deposit(address indexed from, uint256 deposit);
  event Withdrawal(address indexed to, uint256 amount);
  event MintSlippageUpdated(uint256 prev, uint256 current);
  event RedeemSlippageUpdated(uint256 prev, uint256 current);
  event BatchMinted(bytes32 batchId, uint256 suppliedTokenAmount, uint256 butterAmount);
  event BatchRedeemed(bytes32 batchId, uint256 suppliedTokenAmount, uint256 threeCrvAmount);
  event Claimed(address indexed account, BatchType batchType, uint256 shares, uint256 claimedToken);
  event WithdrawnFromBatch(bytes32 batchId, uint256 amount, address indexed to);
  event MovedUnclaimedDepositsIntoCurrentBatch(uint256 amount, BatchType batchType, address indexed account);
  event RedeemThresholdUpdated(uint256 previousThreshold, uint256 newThreshold);
  event MintThresholdUpdated(uint256 previousThreshold, uint256 newThreshold);
  event BatchCooldownUpdated(uint256 previousCooldown, uint256 newCooldown);
  event CurveTokenPairsUpdated(address[] yTokenAddresses, CurvePoolTokenPair[] curveTokenPairs);
  event RedemptionFeeUpdated(uint256 newRedemptionFee, address newFeeRecipient);
  event SweetheartUpdated(address sweetheart, bool isSweeheart);

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry _contractRegistry,
    IStaking _staking,
    ISetToken _setToken,
    IERC20 _threeCrv,
    CurveMetapool _threePool,
    BasicIssuanceModule _basicIssuanceModule,
    address[] memory _yTokenAddresses,
    CurvePoolTokenPair[] memory _curvePoolTokenPairs,
    uint256 _batchCooldown,
    uint256 _mintThreshold,
    uint256 _redeemThreshold
  ) {
    contractRegistry = _contractRegistry;
    staking = _staking;
    setToken = _setToken;
    threeCrv = _threeCrv;
    threePool = _threePool;
    setBasicIssuanceModule = _basicIssuanceModule;

    _setCurvePoolTokenPairs(_yTokenAddresses, _curvePoolTokenPairs);

    batchCooldown = _batchCooldown;
    mintThreshold = _mintThreshold;
    redeemThreshold = _redeemThreshold;
    lastMintedAt = block.timestamp;
    lastRedeemedAt = block.timestamp;

    _generateNextBatch(bytes32("mint"), BatchType.Mint);
    _generateNextBatch(bytes32("redeem"), BatchType.Redeem);
  }

  /* ========== VIEWS ========== */
  /**
   * @notice Get ids for all batches that a user has interacted with
   * @param _account The address for whom we want to retrieve batches
   */
  function getAccountBatches(address _account) external view returns (bytes32[] memory) {
    return accountBatches[_account];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Deposits funds in the current mint batch
   * @param _amount Amount of 3cr3CRV to use for minting
   * @param _depositFor User that gets the shares attributed to (for use in zapper contract)
   */
  function depositForMint(uint256 _amount, address _depositFor) external nonReentrant whenNotPaused {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireApprovedContractOrEOA(msg.sender);
    require(
      IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).hasRole(
        keccak256("ButterZapper"),
        msg.sender
      ) || msg.sender == _depositFor,
      "you cant transfer other funds"
    );
    require(threeCrv.balanceOf(msg.sender) >= _amount, "insufficent balance");
    threeCrv.transferFrom(msg.sender, address(this), _amount);
    _deposit(_amount, currentMintBatchId, _depositFor);
  }

  /**
   * @notice deposits funds in the current redeem batch
   * @param _amount amount of Butter to be redeemed
   */
  function depositForRedeem(uint256 _amount) external nonReentrant whenNotPaused {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireApprovedContractOrEOA(msg.sender);
    require(setToken.balanceOf(msg.sender) >= _amount, "insufficient balance");
    setToken.transferFrom(msg.sender, address(this), _amount);
    _deposit(_amount, currentRedeemBatchId, msg.sender);
  }

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param _batchId From which batch should funds be withdrawn from
   * @param _amountToWithdraw Amount of Butter or 3CRV to be withdrawn from the queue (depending on mintBatch / redeemBatch)
   * @param _withdrawFor User that gets the shares attributed to (for use in zapper contract)
   */
  function withdrawFromBatch(
    bytes32 _batchId,
    uint256 _amountToWithdraw,
    address _withdrawFor
  ) external {
    address recipient = _getRecipient(_withdrawFor);

    Batch storage batch = batches[_batchId];
    uint256 accountBalance = accountBalances[_batchId][_withdrawFor];
    require(batch.claimable == false, "already processed");
    require(accountBalance >= _amountToWithdraw, "account has insufficient funds");

    //At this point the account balance is equal to the supplied token and can be used interchangeably
    accountBalances[_batchId][_withdrawFor] = accountBalance - _amountToWithdraw;
    batch.suppliedTokenBalance = batch.suppliedTokenBalance - _amountToWithdraw;
    batch.unclaimedShares = batch.unclaimedShares - _amountToWithdraw;

    if (batch.batchType == BatchType.Mint) {
      threeCrv.safeTransfer(recipient, _amountToWithdraw);
    } else {
      setToken.safeTransfer(recipient, _amountToWithdraw);
    }
    emit WithdrawnFromBatch(_batchId, _amountToWithdraw, _withdrawFor);
  }

  /**
   * @notice Claims funds after the batch has been processed (get Butter from a mint batch and 3CRV from a redeem batch)
   * @param _batchId Id of batch to claim from
   * @param _claimFor User that gets the shares attributed to (for use in zapper contract)
   */
  function claim(bytes32 _batchId, address _claimFor) external returns (uint256) {
    (address recipient, BatchType batchType, uint256 accountBalance, uint256 tokenAmountToClaim) = _prepareClaim(
      _batchId,
      _claimFor
    );
    //Transfer token
    if (batchType == BatchType.Mint) {
      setToken.safeTransfer(recipient, tokenAmountToClaim);
    } else {
      //We only want to apply a fee on redemption of Butter
      //Sweethearts are partner addresses that we want to exclude from this fee
      if (!sweethearts[_claimFor]) {
        //Fee is deducted from threeCrv -- This allows it to work with the Zapper
        //Fes are denominated in BasisPoints
        uint256 fee = (tokenAmountToClaim * redemptionFeeRate) / 10_000;
        redemptionFees = redemptionFees + fee;
        tokenAmountToClaim = tokenAmountToClaim - fee;
      }
      threeCrv.safeTransfer(recipient, tokenAmountToClaim);
    }
    emit Claimed(recipient, batchType, accountBalance, tokenAmountToClaim);

    return tokenAmountToClaim;
  }

  /**
   * @notice Claims BTR after batch has been processed and stakes it in Staking.sol
   * @param _batchId Id of batch to claim from
   * @param _claimFor User that gets the shares attributed to (for use in zapper contract)
   */
  function claimAndStake(bytes32 _batchId, address _claimFor) external {
    (address recipient, BatchType batchType, uint256 accountBalance, uint256 tokenAmountToClaim) = _prepareClaim(
      _batchId,
      _claimFor
    );
    emit Claimed(recipient, batchType, accountBalance, tokenAmountToClaim);

    //Transfer token
    require(batchType == BatchType.Mint, "Can only stake BTR");
    staking.stakeFor(tokenAmountToClaim, recipient);
  }

  /**
   * @notice Moves unclaimed token (3crv or butter) from their respective Batches into a new redeemBatch / mintBatch without needing to claim them first. This will typically be used when butter has already been minted and a user has never claimed / transfered the token to their address and they would like to convert it to stablecoin.
   * @param _batchIds the ids of each batch where butter should be moved from
   * @param _shares how many shares should redeemed in each of the batches
   * @param _batchType the batchType where funds should be taken from (Mint -> Take Hysi and redeem then, Redeem -> Take 3Crv and Mint Butter)
   * @dev the indices of batchIds must match the amountsInHysi to work properly (This will be done by the frontend)
   */
  function moveUnclaimedDepositsIntoCurrentBatch(
    bytes32[] calldata _batchIds,
    uint256[] calldata _shares,
    BatchType _batchType
  ) external whenNotPaused {
    require(_batchIds.length == _shares.length, "array lengths must match");

    uint256 totalAmount;

    for (uint256 i; i < _batchIds.length; i++) {
      Batch storage batch = batches[_batchIds[i]];
      uint256 accountBalance = accountBalances[batch.batchId][msg.sender];
      //Check that the user has enough funds and that the batch was already minted
      //Only the current redeemBatch is claimable == false so this check allows us to not adjust batch.suppliedTokenBalance
      //Additionally it makes no sense to move funds from the current redeemBatch to the current redeemBatch
      require(batch.claimable == true, "has not yet been processed");
      require(batch.batchType == _batchType, "incorrect batchType");
      require(accountBalance >= _shares[i], "account has insufficient funds");

      uint256 tokenAmountToClaim = (batch.claimableTokenBalance * _shares[i]) / batch.unclaimedShares;
      batch.claimableTokenBalance = batch.claimableTokenBalance - tokenAmountToClaim;
      batch.unclaimedShares = batch.unclaimedShares - _shares[i];
      accountBalances[batch.batchId][msg.sender] = accountBalance - _shares[i];

      totalAmount = totalAmount + tokenAmountToClaim;
    }
    require(totalAmount > 0, "totalAmount must be larger 0");

    if (BatchType.Mint == _batchType) {
      _deposit(totalAmount, currentRedeemBatchId, msg.sender);
    }

    if (BatchType.Redeem == _batchType) {
      _deposit(totalAmount, currentMintBatchId, msg.sender);
    }

    emit MovedUnclaimedDepositsIntoCurrentBatch(totalAmount, _batchType, msg.sender);
  }

  /**
   * @notice Mint Butter token with deposited 3CRV. This function goes through all the steps necessary to mint an optimal amount of Butter
   * @dev This function deposits 3CRV in the underlying Metapool and deposits these LP token to get yToken which in turn are used to mint Butter
   * @dev This process leaves some leftovers which are partially used in the next mint batches.
   * @dev In order to get 3CRV we can implement a zap to move stables into the curve tri-pool
   * @dev handleKeeperIncentive checks if the msg.sender is a permissioned keeper and pays them a reward for calling this function (see KeeperIncentive.sol)
   */
  function batchMint() external whenNotPaused {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireApprovedContractOrEOA(msg.sender);
    IKeeperIncentive(contractRegistry.getContract(keccak256("KeeperIncentive"))).handleKeeperIncentive(
      contractName,
      0,
      msg.sender
    );
    Batch storage batch = batches[currentMintBatchId];

    //Check if there was enough time between the last batch minting and this attempt...
    //...or if enough 3CRV was deposited to make the minting worthwhile
    //This is to prevent excessive gas consumption and costs as we will pay keeper to call this function
    require(
      (block.timestamp - lastMintedAt) >= batchCooldown || (batch.suppliedTokenBalance >= mintThreshold),
      "can not execute batch mint yet"
    );

    //Check if the Batch got already processed -- should technically not be possible
    require(batch.claimable == false, "already minted");

    //Check if this contract has enough 3CRV -- should technically not be necessary
    require(
      threeCrv.balanceOf(address(this)) >= batch.suppliedTokenBalance,
      "account has insufficient balance of token to mint"
    );

    //Get the quantity of yToken for one Butter
    (address[] memory tokenAddresses, uint256[] memory quantities) = setBasicIssuanceModule
      .getRequiredComponentUnitsForIssue(setToken, 1e18);

    //Total value of leftover yToken valued in 3CRV
    uint256 totalLeftoverIn3Crv;

    //Individual yToken leftovers valued in 3CRV
    uint256[] memory leftoversIn3Crv = new uint256[](quantities.length);

    for (uint256 i; i < tokenAddresses.length; i++) {
      //Check how many crvLPToken are needed to mint one yToken
      uint256 yTokenInCrvToken = YearnVault(tokenAddresses[i]).pricePerShare();

      //Check how many 3CRV are needed to mint one crvLPToken
      uint256 crvLPTokenIn3Crv = uint256(2e18) -
        curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool.calc_withdraw_one_coin(1e18, 1);

      //Calculate how many 3CRV are needed to mint one yToken
      uint256 yTokenIn3Crv = (yTokenInCrvToken * crvLPTokenIn3Crv) / 1e18;

      //Calculate how much the yToken leftover are worth in 3CRV
      uint256 leftoverIn3Crv = (YearnVault(tokenAddresses[i]).balanceOf(address(this)) * yTokenIn3Crv) / 1e18;

      //Add the leftover value to the array of leftovers for later use
      leftoversIn3Crv[i] = leftoverIn3Crv;

      //Add the leftover value to the total leftover value
      totalLeftoverIn3Crv = totalLeftoverIn3Crv + leftoverIn3Crv;
    }

    //Calculate the total value of supplied token + leftovers in 3CRV
    uint256 suppliedTokenBalancePlusLeftovers = batch.suppliedTokenBalance + totalLeftoverIn3Crv;

    for (uint256 i; i < tokenAddresses.length; i++) {
      //Calculate the pool allocation by dividing the suppliedTokenBalance by number of token addresses and take leftovers into account
      uint256 poolAllocation = suppliedTokenBalancePlusLeftovers / tokenAddresses.length - leftoversIn3Crv[i];

      //Pool 3CRV to get crvLPToken
      _sendToCurve(poolAllocation, curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool);

      //Deposit crvLPToken to get yToken
      _sendToYearn(
        curvePoolTokenPairs[tokenAddresses[i]].crvLPToken.balanceOf(address(this)),
        YearnVault(tokenAddresses[i])
      );

      //Approve yToken for minting
      YearnVault(tokenAddresses[i]).safeIncreaseAllowance(
        address(setBasicIssuanceModule),
        YearnVault(tokenAddresses[i]).balanceOf(address(this))
      );
    }

    //Get the minimum amount of butter that we can mint with our balances of yToken
    uint256 butterAmount = (YearnVault(tokenAddresses[0]).balanceOf(address(this)) * 1e18) / quantities[0];

    for (uint256 i = 1; i < tokenAddresses.length; i++) {
      butterAmount = Math.min(
        butterAmount,
        (YearnVault(tokenAddresses[i]).balanceOf(address(this)) * 1e18) / quantities[i]
      );
    }

    require(
      butterAmount >=
        getMinAmountToMint(
          valueOf3Crv(batch.suppliedTokenBalance),
          valueOfComponents(tokenAddresses, quantities),
          mintSlippage
        ),
      "slippage too high"
    );

    //Mint Butter
    setBasicIssuanceModule.issue(setToken, butterAmount, address(this));

    //Save the minted amount Butter as claimable token for the batch
    batch.claimableTokenBalance = butterAmount;

    //Set claimable to true so users can claim their Butter
    batch.claimable = true;

    //Update lastMintedAt for cooldown calculations
    lastMintedAt = block.timestamp;

    emit BatchMinted(currentMintBatchId, batch.suppliedTokenBalance, butterAmount);

    //Create the next mint batch
    _generateNextBatch(currentMintBatchId, BatchType.Mint);
  }

  /**
   * @notice Redeems Butter for 3CRV. This function goes through all the steps necessary to get 3CRV
   * @dev This function reedeems Butter for the underlying yToken and deposits these yToken in curve Metapools for 3CRV
   * @dev In order to get stablecoins from 3CRV we can use a zap to redeem 3CRV for stables in the curve tri-pool
   * @dev handleKeeperIncentive checks if the msg.sender is a permissioned keeper and pays them a reward for calling this function (see KeeperIncentive.sol)
   */
  function batchRedeem() external whenNotPaused {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireApprovedContractOrEOA(msg.sender);
    IKeeperIncentive(contractRegistry.getContract(keccak256("KeeperIncentive"))).handleKeeperIncentive(
      contractName,
      1,
      msg.sender
    );
    Batch storage batch = batches[currentRedeemBatchId];

    //Check if there was enough time between the last batch redemption and this attempt...
    //...or if enough Butter was deposited to make the redemption worthwhile
    //This is to prevent excessive gas consumption and costs as we will pay keeper to call this function
    require(
      (block.timestamp - lastRedeemedAt >= batchCooldown) || (batch.suppliedTokenBalance >= redeemThreshold),
      "can not execute batch redeem yet"
    );

    //Check if the Batch got already processed
    require(batch.claimable == false, "already redeemed");

    //Get tokenAddresses for mapping of underlying
    (address[] memory tokenAddresses, uint256[] memory quantities) = setBasicIssuanceModule
      .getRequiredComponentUnitsForIssue(setToken, batch.suppliedTokenBalance);

    //Allow setBasicIssuanceModule to use Butter
    _setBasicIssuanceModuleAllowance(batch.suppliedTokenBalance);

    //Redeem Butter for yToken
    setBasicIssuanceModule.redeem(setToken, batch.suppliedTokenBalance, address(this));

    //Check our balance of 3CRV since we could have some still around from previous batches
    uint256 oldBalance = threeCrv.balanceOf(address(this));

    for (uint256 i; i < tokenAddresses.length; i++) {
      //Deposit yToken to receive crvLPToken
      _withdrawFromYearn(YearnVault(tokenAddresses[i]).balanceOf(address(this)), YearnVault(tokenAddresses[i]));

      uint256 crvLPTokenBalance = curvePoolTokenPairs[tokenAddresses[i]].crvLPToken.balanceOf(address(this));

      //Deposit crvLPToken to receive 3CRV
      _withdrawFromCurve(crvLPTokenBalance, curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool);
    }

    //Save the redeemed amount of 3CRV as claimable token for the batch
    batch.claimableTokenBalance = threeCrv.balanceOf(address(this)) - oldBalance;

    require(
      batch.claimableTokenBalance >=
        getMinAmount3CrvFromRedeem(valueOfComponents(tokenAddresses, quantities), redeemSlippage),
      "slippage too high"
    );

    emit BatchRedeemed(currentRedeemBatchId, batch.suppliedTokenBalance, batch.claimableTokenBalance);

    //Set claimable to true so users can claim their Butter
    batch.claimable = true;

    //Update lastRedeemedAt for cooldown calculations
    lastRedeemedAt = block.timestamp;

    //Create the next redeem batch id
    _generateNextBatch(currentRedeemBatchId, BatchType.Redeem);
  }

  /**
   * @notice sets approval for contracts that require access to assets held by this contract
   */
  function setApprovals() external {
    (address[] memory tokenAddresses, ) = setBasicIssuanceModule.getRequiredComponentUnitsForIssue(setToken, 1e18);

    for (uint256 i; i < tokenAddresses.length; i++) {
      IERC20 curveLpToken = curvePoolTokenPairs[tokenAddresses[i]].crvLPToken;
      CurveMetapool curveMetapool = curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool;
      YearnVault yearnVault = YearnVault(tokenAddresses[i]);

      threeCrv.safeApprove(address(curveMetapool), 0);
      threeCrv.safeApprove(address(curveMetapool), type(uint256).max);

      curveLpToken.safeApprove(address(yearnVault), 0);
      curveLpToken.safeApprove(address(yearnVault), type(uint256).max);

      curveLpToken.safeApprove(address(curveMetapool), 0);
      curveLpToken.safeApprove(address(curveMetapool), type(uint256).max);
    }

    setToken.safeApprove(address(staking), 0);
    setToken.safeApprove(address(staking), type(uint256).max);
  }

  function getMinAmountToMint(
    uint256 _valueOfBatch,
    uint256 _valueOfComponentsPerUnit,
    uint256 _slippage
  ) public pure returns (uint256) {
    uint256 _mintAmount = (_valueOfBatch * 1e18) / _valueOfComponentsPerUnit;
    uint256 _delta = (_mintAmount * _slippage) / 10_000;
    return _mintAmount - _delta;
  }

  function getMinAmount3CrvFromRedeem(uint256 _valueOfComponents, uint256 _slippage) public view returns (uint256) {
    uint256 _threeCrvToReceive = (_valueOfComponents * 1e18) / threePool.get_virtual_price();
    uint256 _delta = (_threeCrvToReceive * _slippage) / 10_000;
    return _threeCrvToReceive - _delta;
  }

  function valueOfComponents(address[] memory _tokenAddresses, uint256[] memory _quantities)
    public
    view
    returns (uint256)
  {
    uint256 value;
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      value +=
        (((YearnVault(_tokenAddresses[i]).pricePerShare() *
          curvePoolTokenPairs[_tokenAddresses[i]].curveMetaPool.get_virtual_price()) / 1e18) * _quantities[i]) /
        1e18;
    }
    return value;
  }

  function valueOf3Crv(uint256 _units) public view returns (uint256) {
    return (_units * threePool.get_virtual_price()) / 1e18;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
   * @notice sets slippage for minting
   * @param _slippageAmount amount in bps (e.g. 50 = 0.5%)
   */
  function setMintSlippage(uint256 _slippageAmount) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    require(_slippageAmount <= 200, "slippage too high");
    emit MintSlippageUpdated(mintSlippage, _slippageAmount);
    mintSlippage = _slippageAmount;
  }

  /**
   * @notice sets slippage for redeeming
   * @param _slippageAmount amount in bps (e.g. 50 = 0.5%)
   */
  function setRedeemSlippage(uint256 _slippageAmount) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    require(_slippageAmount <= 200, "slippage too high");
    emit RedeemSlippageUpdated(redeemSlippage, _slippageAmount);
    redeemSlippage = _slippageAmount;
  }

  /**
   * @notice sets allowance for basic issuance module
   * @param _amount amount to approve
   */
  function _setBasicIssuanceModuleAllowance(uint256 _amount) internal {
    setToken.safeApprove(address(setBasicIssuanceModule), 0);
    setToken.safeApprove(address(setBasicIssuanceModule), _amount);
  }

  /**
   * @notice makes sure only zapper or user can withdraw from accout_ and returns the recipient of the withdrawn token
   * @param _account is the address which gets withdrawn from
   * @dev returns recipient of the withdrawn funds
   * @dev By default a user should set _account to their address
   * @dev If zapper is used to withdraw and swap for a user the msg.sender will be zapper and _account is the user which we withdraw from. The zapper than sends the swapped funds afterwards to the user
   */
  function _getRecipient(address _account) internal view returns (address) {
    //Make sure that only zapper can withdraw from someone else
    require(
      IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).hasRole(
        keccak256("ButterZapper"),
        msg.sender
      ) || msg.sender == _account,
      "you cant transfer other funds"
    );

    //Set recipient per default to _account
    address recipient = _account;

    //set the recipient to zapper if its called by the zapper
    if (
      IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).hasRole(
        keccak256("ButterZapper"),
        msg.sender
      )
    ) {
      recipient = msg.sender;
    }
    return recipient;
  }

  /**
   * @notice Generates the next batch id for new deposits
   * @param _currentBatchId takes the current mint or redeem batch id
   * @param _batchType BatchType of the newly created id
   */
  function _generateNextBatch(bytes32 _currentBatchId, BatchType _batchType) internal returns (bytes32) {
    bytes32 id = _generateNextBatchId(_currentBatchId);
    batchIds.push(id);
    Batch storage batch = batches[id];
    batch.batchType = _batchType;
    batch.batchId = id;

    if (BatchType.Mint == _batchType) {
      currentMintBatchId = id;
      batch.suppliedTokenAddress = address(threeCrv);
      batch.claimableTokenAddress = address(setToken);
    }
    if (BatchType.Redeem == _batchType) {
      currentRedeemBatchId = id;
      batch.suppliedTokenAddress = address(setToken);
      batch.claimableTokenAddress = address(threeCrv);
    }
    return id;
  }

  /**
   * @notice Deposit either Butter or 3CRV in their respective batches
   * @param _amount The amount of 3CRV or Butter a user is depositing
   * @param _currentBatchId The current reedem or mint batch id to place the funds in the next batch to be processed
   * @param _depositFor User that gets the shares attributed to (for use in zapper contract)
   * @dev This function will be called by depositForMint or depositForRedeem and simply reduces code duplication
   */
  function _deposit(
    uint256 _amount,
    bytes32 _currentBatchId,
    address _depositFor
  ) internal {
    Batch storage batch = batches[_currentBatchId];

    //Add the new funds to the batch
    batch.suppliedTokenBalance = batch.suppliedTokenBalance + _amount;
    batch.unclaimedShares = batch.unclaimedShares + _amount;
    accountBalances[_currentBatchId][_depositFor] = accountBalances[_currentBatchId][_depositFor] + _amount;

    //Save the batchId for the user so they can be retrieved to claim the batch
    if (
      accountBatches[_depositFor].length == 0 ||
      accountBatches[_depositFor][accountBatches[_depositFor].length - 1] != _currentBatchId
    ) {
      accountBatches[_depositFor].push(_currentBatchId);
    }

    emit Deposit(_depositFor, _amount);
  }

  /**
   * @notice This function checks all requirements for claiming, updates batches and balances and returns the values needed for the final transfer of tokens
   * @param _batchId Id of batch to claim from
   * @param _claimFor User that gets the shares attributed to (for use in zapper contract)
   */
  function _prepareClaim(bytes32 _batchId, address _claimFor)
    internal
    returns (
      address,
      BatchType,
      uint256,
      uint256
    )
  {
    Batch storage batch = batches[_batchId];
    require(batch.claimable, "not yet claimable");

    address recipient = _getRecipient(_claimFor);
    uint256 accountBalance = accountBalances[_batchId][_claimFor];
    require(accountBalance <= batch.unclaimedShares, "claiming too many shares");

    //Calculate how many token will be claimed
    uint256 tokenAmountToClaim = (batch.claimableTokenBalance * accountBalance) / batch.unclaimedShares;

    //Subtract the claimed token from the batch
    batch.claimableTokenBalance = batch.claimableTokenBalance - tokenAmountToClaim;
    batch.unclaimedShares = batch.unclaimedShares - accountBalance;
    accountBalances[_batchId][_claimFor] = 0;

    return (recipient, batch.batchType, accountBalance, tokenAmountToClaim);
  }

  /**
   * @notice Deposit 3CRV in a curve metapool for its LP-Token
   * @param _amount The amount of 3CRV that gets deposited
   * @param _curveMetapool The metapool where we want to provide liquidity
   */
  function _sendToCurve(uint256 _amount, CurveMetapool _curveMetapool) internal {
    //Takes 3CRV and sends lpToken to this contract
    //Metapools take an array of amounts with the exoctic stablecoin at the first spot and 3CRV at the second.
    //The second variable determines the min amount of LP-Token we want to receive (slippage control)
    _curveMetapool.add_liquidity([0, _amount], 0);
  }

  /**
   * @notice Withdraws 3CRV for deposited crvLPToken
   * @param _amount The amount of crvLPToken that get deposited
   * @param _curveMetapool The metapool where we want to provide liquidity
   */
  function _withdrawFromCurve(uint256 _amount, CurveMetapool _curveMetapool) internal {
    //Takes lp Token and sends 3CRV to this contract
    //The second variable is the index for the token we want to receive (0 = exotic stablecoin, 1 = 3CRV)
    //The third variable determines min amount of token we want to receive (slippage control)
    _curveMetapool.remove_liquidity_one_coin(_amount, 1, 0);
  }

  /**
   * @notice Deposits crvLPToken for yToken
   * @param _amount The amount of crvLPToken that get deposited
   * @param _yearnVault The yearn Vault in which we deposit
   */
  function _sendToYearn(uint256 _amount, YearnVault _yearnVault) internal {
    //Mints yToken and sends them to msg.sender (this contract)
    _yearnVault.deposit(_amount);
  }

  /**
   * @notice Withdraw crvLPToken from yearn
   * @param _amount The amount of crvLPToken which we deposit
   * @param _yearnVault The yearn Vault in which we deposit
   */
  function _withdrawFromYearn(uint256 _amount, YearnVault _yearnVault) internal {
    //Takes yToken and sends crvLPToken to this contract
    _yearnVault.withdraw(_amount);
  }

  /**
   * @notice Generates the next batch id for new deposits
   * @param _currentBatchId takes the current mint or redeem batch id
   */
  function _generateNextBatchId(bytes32 _currentBatchId) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(block.timestamp, _currentBatchId));
  }

  /* ========== ADMIN ========== */

  /**
   * @notice This function allows the owner to change the composition of underlying token of the Butter
   * @param _yTokenAddresses An array of addresses for the yToken needed to mint Butter
   * @param _curvePoolTokenPairs An array structs describing underlying yToken, crvToken and curve metapool
   */
  function setCurvePoolTokenPairs(address[] memory _yTokenAddresses, CurvePoolTokenPair[] calldata _curvePoolTokenPairs)
    public
  {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    _setCurvePoolTokenPairs(_yTokenAddresses, _curvePoolTokenPairs);
  }

  /**
   * @notice This function defines which underlying token and pools are needed to mint a butter token
   * @param _yTokenAddresses An array of addresses for the yToken needed to mint Butter
   * @param _curvePoolTokenPairs An array structs describing underlying yToken, crvToken and curve metapool
   * @dev since our calculations for minting just iterate through the index and match it with the quantities given by Set
   * @dev we must make sure to align them correctly by index, otherwise our whole calculation breaks down
   */
  function _setCurvePoolTokenPairs(address[] memory _yTokenAddresses, CurvePoolTokenPair[] memory _curvePoolTokenPairs)
    internal
  {
    emit CurveTokenPairsUpdated(_yTokenAddresses, _curvePoolTokenPairs);
    for (uint256 i; i < _yTokenAddresses.length; i++) {
      curvePoolTokenPairs[_yTokenAddresses[i]] = _curvePoolTokenPairs[i];
    }
  }

  /**
   * @notice Changes the current batch cooldown
   * @param _cooldown Cooldown in seconds
   * @dev The cooldown is the same for redeem and mint batches
   */
  function setBatchCooldown(uint256 _cooldown) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit BatchCooldownUpdated(batchCooldown, _cooldown);
    batchCooldown = _cooldown;
  }

  /**
   * @notice Changes the Threshold of 3CRV which need to be deposited to be able to mint immediately
   * @param _threshold Amount of 3CRV necessary to mint immediately
   */
  function setMintThreshold(uint256 _threshold) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit MintThresholdUpdated(mintThreshold, _threshold);
    mintThreshold = _threshold;
  }

  /**
   * @notice Changes the Threshold of Butter which need to be deposited to be able to redeem immediately
   * @param _threshold Amount of Butter necessary to mint immediately
   */
  function setRedeemThreshold(uint256 _threshold) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    emit RedeemThresholdUpdated(redeemThreshold, _threshold);
    redeemThreshold = _threshold;
  }

  /**
   * @notice Changes the redemption fee rate and the fee recipient
   * @param _feeRate Redemption fee rate in basis points
   * @param _recipient The recipient which receives these fees (Should be DAO treasury)
   * @dev Per default both of these values are not set. Therefore a fee has to be explicitly be set with this function
   */
  function setRedemptionFee(uint256 _feeRate, address _recipient) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    require(_feeRate <= 100, "dont get greedy");
    redemptionFeeRate = _feeRate;
    feeRecipient = _recipient;
    emit RedemptionFeeUpdated(_feeRate, _recipient);
  }

  /**
   * @notice Claims all accumulated redemption fees in 3CRV
   */
  function claimRedemptionFee() external {
    threeCrv.safeTransfer(feeRecipient, redemptionFees);
    redemptionFees = 0;
  }

  /**
   * @notice Toggles an address as Sweetheart (partner addresses that don't pay a redemption fee)
   * @param _sweetheart The address that shall become/lose their sweetheart status
   */
  function updateSweetheart(address _sweetheart, bool _enabled) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    sweethearts[_sweetheart] = _enabled;
    emit SweetheartUpdated(_sweetheart, _enabled);
  }

  /**
   * @notice Pauses the contract.
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function pause() external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    _pause();
  }

  /**
   * @notice Unpauses the contract.
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function unpause() external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    _unpause();
  }
}
