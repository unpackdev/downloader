// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./ContractRegistryAccess.sol";
import "./ACLAuth.sol";
import "./KeeperIncentivized.sol";
import "./YearnVault.sol";
import "./BasicIssuanceModule.sol";
import "./ISetToken.sol";
import "./Curve3Pool.sol";
import "./CurveContracts.sol";
import "./IAngleRouter.sol";
import "./IContractRegistry.sol";
import "./IBatchStorage.sol";
import "./ThreeXBatchVault.sol";
import "./AbstractBatchController.sol";
import "./SafeERC20.sol";

/**
 * @notice Defines if the Batch will mint or redeem 3X
 */

/*
 * @notice This Contract allows smaller depositors to mint and redeem 3X without needing to through all the steps necessary on their own,
 * which not only takes long but mainly costs enormous amounts of gas.
 * The 3X is created from several different yTokens which in turn need each a deposit of a crvLPToken.
 * This means multiple approvals and deposits are necessary to mint one 3X.
 * We batch this process and allow users to pool their funds. Then we pay a keeper to mint or redeem 3X regularly.
 */
contract ThreeXBatchProcessing is ACLAuth, KeeperIncentivized, AbstractBatchController, ContractRegistryAccess {
  using SafeERC20 for YearnVault;
  using SafeERC20 for ISetToken;
  using SafeERC20 for IERC20;
  using SafeERC20 for CurveMetapool;

  /**
   * @notice each component has dependencies that form a path to aquire and subsequently swap out of the component. these are those dependenices
   * @param swapPool A CurveMetaPool for trading USDC against FRAX
   * @param curveMetaPool A CurveMetaPool that we want to deploy into yearn (D3, 3EUR)
   * @param angleRouter The Angle Router to trade USDC against agEUR
   */
  struct ComponentDependencies {
    CurveMetapool swapPool;
    CurveMetapool curveMetaPool;
    IAngleRouter angleRouter;
  }

  /* ========== STATE VARIABLES ========== */

  bytes32 public constant contractName = "ThreeXBatchProcessing";

  mapping(address => bool) public batchStorageApprovals;

  // Maps yToken Address (which is used in the SetToken) to its underlying Token
  mapping(address => ComponentDependencies) public componentDependencies;

  // FRAX and agEUR which we use as intermediate token to deploy/withdraw from the curveMetapools
  IERC20[2] public swapToken;

  BasicIssuanceModule public basicIssuanceModule;

  /* ========== EVENTS ========== */

  // todo move logs to lower level in AbstractBatchVault.sol
  event BatchMinted(bytes32 batchId, uint256 suppliedTokenAmount, uint256 outputAmount);
  event BatchRedeemed(bytes32 batchId, uint256 suppliedTokenAmount, uint256 outputAmount);
  event ComponentDependenciesUpdated(address[] components, ComponentDependencies[] componentDependencies);

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry __contractRegistry,
    IStaking _staking,
    AbstractBatchStorage _batchStorage,
    BatchTokens memory _mintBatchTokens,
    BatchTokens memory _redeemBatchTokens,
    BasicIssuanceModule _basicIssuanceModule,
    address[] memory _componentAddresses,
    ComponentDependencies[] memory _componentDependencies,
    IERC20[2] memory _swapToken,
    ProcessingThreshold memory _processingThreshold
  ) AbstractBatchController(__contractRegistry, _batchStorage) ContractRegistryAccess(__contractRegistry) {
    staking = _staking;
    basicIssuanceModule = _basicIssuanceModule;
    swapToken = _swapToken;

    mintBatchTokens = _mintBatchTokens;
    redeemBatchTokens = _redeemBatchTokens;

    _setComponents(_componentAddresses, _componentDependencies);

    processingThreshold = _processingThreshold;

    lastMintedAt = block.timestamp;
    lastRedeemedAt = block.timestamp;

    _createBatch(BatchType.Mint);
    _createBatch(BatchType.Redeem);

    slippage.mintBps = 50;
    slippage.redeemBps = 50;

    _setFee("mint", 50, address(0), mintBatchTokens.targetToken);
    _setFee("redeem", 50, address(0), redeemBatchTokens.targetToken);

    _setApprovals();
  }

  function getMinAmountToMint(
    uint256 _valueOfBatch,
    uint256 _valueOfComponentsPerUnit,
    uint256 _slippage
  ) public pure returns (uint256) {
    uint256 mintAmount = (_valueOfBatch * 1e18) / _valueOfComponentsPerUnit;
    uint256 delta = (mintAmount * _slippage) / 10_000;
    return mintAmount - delta;
  }

  function getMinAmountFromRedeem(uint256 _valueOfComponents, uint256 _slippage) public pure returns (uint256) {
    uint256 delta = (_valueOfComponents * _slippage) / 10_000;
    return (_valueOfComponents - delta) / 1e12;
  }

  function valueOfComponents(address[] memory _tokenAddresses, uint256[] memory _quantities)
    public
    view
    returns (uint256)
  {
    uint256 value;
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      // d3pool must be i == 0
      uint256 lpTokenPriceInUSD = i == 0
        ? componentDependencies[_tokenAddresses[i]].curveMetaPool.get_virtual_price()
        : (componentDependencies[_tokenAddresses[i]].curveMetaPool.get_virtual_price() *
          componentDependencies[_tokenAddresses[i]].swapPool.price_oracle()) / 1e18;

      value += (((lpTokenPriceInUSD * YearnVault(_tokenAddresses[i]).pricePerShare()) / 1e18) * _quantities[i]) / 1e18;
    }
    return value;
  }

  //

  function _getPoolAllocationAndRatio(
    address _component,
    uint256 _quantity,
    uint256 _suppliedTokenBalance,
    uint256 _setValue,
    uint256 _i
  ) internal view returns (uint256 poolAllocation, uint256 ratio) {
    uint256 lpTokenPriceInUSD = _i == 0
      ? componentDependencies[_component].curveMetaPool.get_virtual_price()
      : (componentDependencies[_component].curveMetaPool.get_virtual_price() *
        componentDependencies[_component].swapPool.price_oracle()) / 1e18;

    // Calculate the virtualPrice of one yToken
    uint256 componentValuePerShare = (YearnVault(_component).pricePerShare() * lpTokenPriceInUSD) / 1e18;

    //Calculate the value of quantity (of yToken) in virtualPrice
    uint256 componentValuePerSet = (_quantity * componentValuePerShare) / 1e18;

    //Calculate the value of leftover yToken in virtualPrice
    uint256 componentValueHeldByContract = (YearnVault(_component).balanceOf(address(this)) * componentValuePerShare) /
      1e18;

    ratio = (componentValuePerSet * 1e18) / _setValue;
    poolAllocation = _getPoolAllocation(_suppliedTokenBalance, ratio) - (componentValueHeldByContract / 1e12);

    return (poolAllocation, ratio);
  }

  /**
   * @notice returns the amount of USDC that should be allocated for a curveMetapool
   * @param _balance the max amount of USDC that is available in this iteration
   * @param _ratio the ratio of USDC needed to get enough yToken to mint 3X
   */
  function _getPoolAllocation(uint256 _balance, uint256 _ratio) internal pure returns (uint256) {
    return ((_balance * _ratio) / 1e18);
  }

  /**
   * @notice Mint 3X token with deposited USDC. This function goes through all the steps necessary to mint an optimal amount of 3X
   * @dev This function deposits USDC in the underlying Metapool and deposits these LP token to get yToken which in turn are used to mint 3X
   * @dev This process leaves some leftovers which are partially used in the next mint batches.
   * @dev In order to get USDC we can implement a zap to move stables into the curve tri-pool
   * @dev handleKeeperIncentive checks if the msg.sender is a permissioned keeper and pays them a reward for calling this function (see KeeperIncentive.sol)
   */
  function batchMint() external whenNotPaused keeperIncentive(contractName, 0) {
    Batch memory batch = this.getBatch(currentMintBatchId);

    // Check if there was enough time between the last batch minting and this attempt...
    // ...or if enough Ib-Token was deposited to make the minting worthwhile
    // This is to prevent excessive gas consumption and costs as we will pay keeper to call this function
    require(
      (block.timestamp - lastMintedAt) >= processingThreshold.batchCooldown ||
        (batch.sourceTokenBalance >= processingThreshold.mintThreshold),
      "can not execute batch mint yet"
    );

    // Check if the Batch got already processed -- should technically not be possible
    require(batch.claimable == false, "already minted");

    // Check if this contract has enough USDC -- should technically not be necessary
    require(
      mintBatchTokens.sourceToken.balanceOf(address(batchStorage)) >= batch.sourceTokenBalance,
      "account has insufficient balance of token to mint"
    );

    // Get the quantity of yToken for one 3X
    (address[] memory tokenAddresses, uint256[] memory quantities) = basicIssuanceModule
      .getRequiredComponentUnitsForIssue(ISetToken(address(mintBatchTokens.targetToken)), 1e18);

    uint256 setValue = valueOfComponents(tokenAddresses, quantities);

    // Remaining amount of USDC in this batch which hasnt been allocated yet
    uint256 remainingBatchBalanceValue = batch.sourceTokenBalance;

    // Temporary allocation of USDC to be deployed in curveMetapools
    uint256[] memory poolAllocations = new uint256[](quantities.length);

    uint256[] memory ratios = new uint256[](quantities.length);

    // transfer batch supplied tokens to this contract
    uint256 sourceTokenBalance = batchStorage.withdrawSourceTokenFromBatch(currentMintBatchId);

    for (uint256 i; i < tokenAddresses.length; i++) {
      // prettier-ignore
      (uint256 allocation, uint256 ratio) = _getPoolAllocationAndRatio(tokenAddresses[i], quantities[i], sourceTokenBalance, setValue,i);
      poolAllocations[i] = allocation;
      ratios[i] = ratio;
      remainingBatchBalanceValue -= allocation;
    }

    for (uint256 i; i < tokenAddresses.length; i++) {
      uint256 poolAllocation;

      if (remainingBatchBalanceValue > 0) {
        poolAllocation = _getPoolAllocation(remainingBatchBalanceValue, ratios[i]);
      }

      //Pool USDC to get crvLPToken via the swapPools
      _sendToCurve(poolAllocation + poolAllocations[i], componentDependencies[tokenAddresses[i]], i);

      //Deposit crvLPToken to get yToken
      _sendToYearn(
        componentDependencies[tokenAddresses[i]].curveMetaPool.balanceOf(address(this)),
        YearnVault(tokenAddresses[i])
      );

      //Approve yToken for minting
      YearnVault(tokenAddresses[i]).safeIncreaseAllowance(
        address(basicIssuanceModule),
        YearnVault(tokenAddresses[i]).balanceOf(address(this))
      );
    }

    //Get the minimum amount of 3X that we can mint with our balances of yToken
    uint256 setTokenAmount = (YearnVault(tokenAddresses[0]).balanceOf(address(this)) * 1e18) / quantities[0];

    for (uint256 i = 1; i < tokenAddresses.length; i++) {
      setTokenAmount = Math.min(
        setTokenAmount,
        (YearnVault(tokenAddresses[i]).balanceOf(address(this)) * 1e18) / quantities[i]
      );
    }

    uint256 minMintAmount = getMinAmountToMint(
      sourceTokenBalance * 1e12,
      valueOfComponents(tokenAddresses, quantities),
      slippage.mintBps
    );

    require(setTokenAmount >= minMintAmount, "slippage too high");

    uint256 setTokenAmountLessFees = _takeFee(
      "mint",
      setTokenAmount - minMintAmount,
      setTokenAmount,
      mintBatchTokens.targetToken
    );

    //Mint 3X
    basicIssuanceModule.issue(ISetToken(address(mintBatchTokens.targetToken)), setTokenAmount, address(this));

    batchStorage.depositTargetTokensIntoBatch(currentMintBatchId, setTokenAmountLessFees);

    //Update lastMintedAt for cooldown calculations
    lastMintedAt = block.timestamp;

    emit BatchMinted(currentMintBatchId, sourceTokenBalance, setTokenAmount);

    //Create the next mint batch
    _createBatch(BatchType.Mint);
  }

  function _approveBatchStorage(IERC20 token) internal {
    if (!batchStorageApprovals[address(token)]) {
      token.safeApprove(address(batchStorage), type(uint256).max);
      batchStorageApprovals[address(token)] = true;
    }
  }

  /**
   * @notice Redeems 3X for USDC. This function goes through all the steps necessary to get USDC
   * @dev This function reedeems 3X for the underlying yToken and deposits these yToken in curve Metapools for USDC
   * @dev In order to get other stablecoins from USDC we can use a zap to redeem USDC for stables in the curve tri-pool
   * @dev handleKeeperIncentive checks if the msg.sender is a permissioned keeper and pays them a reward for calling this function (see KeeperIncentive.sol)
   */
  function batchRedeem() external whenNotPaused keeperIncentive(contractName, 1) {
    Batch memory batch = this.getBatch(currentRedeemBatchId);

    //Check if there was enough time between the last batch redemption and this attempt...
    //...or if enough 3X was deposited to make the redemption worthwhile
    //This is to prevent excessive gas consumption and costs as we will pay keeper to call this function
    require(
      (block.timestamp - lastRedeemedAt >= processingThreshold.batchCooldown) ||
        (batch.sourceTokenBalance >= processingThreshold.redeemThreshold),
      "can not execute batch redeem yet"
    );

    //Check if the Batch got already processed
    require(batch.claimable == false, "already redeemed");

    uint256 sourceTokenBalance = batchStorage.withdrawSourceTokenFromBatch(currentRedeemBatchId);

    //Get tokenAddresses for mapping of underlying
    (address[] memory tokenAddresses, uint256[] memory quantities) = basicIssuanceModule
      .getRequiredComponentUnitsForIssue(ISetToken(address(mintBatchTokens.targetToken)), batch.sourceTokenBalance);

    //Allow setBasicIssuanceModule to use 3X
    _setBasicIssuanceModuleAllowance(sourceTokenBalance);

    //Redeem 3X for yToken
    basicIssuanceModule.redeem(
      ISetToken(address(redeemBatchTokens.sourceToken)),
      batch.sourceTokenBalance,
      address(this)
    );

    for (uint256 i; i < tokenAddresses.length; i++) {
      //Deposit yToken to receive crvLPToken
      _withdrawFromYearn(YearnVault(tokenAddresses[i]).balanceOf(address(this)), YearnVault(tokenAddresses[i]));

      //Deposit crvLPToken to receive USDC
      _withdrawFromCurve(
        componentDependencies[tokenAddresses[i]].curveMetaPool.balanceOf(address(this)),
        componentDependencies[tokenAddresses[i]],
        i
      );
    }

    uint256 claimableTokenBalance = batch.targetToken.balanceOf(address(this)) - fees["redeem"].accumulated;

    uint256 minRedeemAmount = getMinAmountFromRedeem(valueOfComponents(tokenAddresses, quantities), slippage.redeemBps);

    require(claimableTokenBalance >= minRedeemAmount, "slippage too high");

    uint256 claimableTokenBalanceLessFees = _takeFee(
      "redeem",
      claimableTokenBalance - minRedeemAmount,
      claimableTokenBalance,
      batch.targetToken
    );

    emit BatchRedeemed(currentRedeemBatchId, batch.sourceTokenBalance, claimableTokenBalance);

    batchStorage.depositTargetTokensIntoBatch(currentRedeemBatchId, claimableTokenBalanceLessFees);

    //Update lastRedeemedAt for cooldown calculations
    lastRedeemedAt = block.timestamp;

    //Create the next redeem batch id
    _createBatch(BatchType.Redeem);
  }

  /**
   * @notice sets approval for contracts that require access to assets held by this contract
   */
  function _setApprovals() internal {
    (address[] memory yToken, ) = basicIssuanceModule.getRequiredComponentUnitsForIssue(
      ISetToken(address(mintBatchTokens.targetToken)),
      1e18
    );

    for (uint256 i; i < yToken.length; i++) {
      CurveMetapool curveMetapool = componentDependencies[yToken[i]].curveMetaPool;

      if (i == 0) {
        mintBatchTokens.sourceToken.safeApprove(address(componentDependencies[yToken[i]].swapPool), type(uint256).max);
        swapToken[i].safeApprove(address(componentDependencies[yToken[i]].swapPool), type(uint256).max);
      } else {
        mintBatchTokens.sourceToken.safeApprove(
          address(componentDependencies[yToken[i]].angleRouter),
          type(uint256).max
        );
        swapToken[i].safeApprove(address(componentDependencies[yToken[i]].angleRouter), type(uint256).max);
      }

      swapToken[i].safeApprove(address(curveMetapool), type(uint256).max);

      curveMetapool.safeApprove(yToken[i], type(uint256).max);

      curveMetapool.safeApprove(address(curveMetapool), type(uint256).max);
    }

    _approveBatchStorage(redeemBatchTokens.sourceToken);
    _approveBatchStorage(redeemBatchTokens.targetToken);
    _approveBatchStorage(mintBatchTokens.sourceToken);
    _approveBatchStorage(mintBatchTokens.targetToken);

    mintBatchTokens.targetToken.safeApprove(address(staking), type(uint256).max);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
   * @notice sets allowance for basic issuance module
   * @param _amount amount to approve
   */
  function _setBasicIssuanceModuleAllowance(uint256 _amount) internal {
    mintBatchTokens.targetToken.safeApprove(address(basicIssuanceModule), 0);
    mintBatchTokens.targetToken.safeApprove(address(basicIssuanceModule), _amount);
  }

  /**
   * @notice Trade USDC for intermediate swapToken and deposit those into the destination curveMetapool
   * @param _amount The amount of USDC that gets deposited
   * @param _contracts ComponentDependencies (swapPool, curveMetapool and AngleRouter)
   * @param _i index of the component (0 == d3, 1 == 3eur)
   */
  function _sendToCurve(
    uint256 _amount,
    ComponentDependencies memory _contracts,
    uint256 _i
  ) internal {
    // Trade USDC for intermediate swapToken
    uint256 destAmount;
    if (_i == 0) {
      destAmount = _contracts.swapPool.exchange_underlying(2, 0, _amount, 0);
    } else {
      _contracts.angleRouter.mint(
        address(this),
        _amount,
        0,
        address(swapToken[_i]),
        address(mintBatchTokens.sourceToken)
      );
      destAmount = swapToken[_i].balanceOf(address(this));
    }

    // Pool swapToken for curveMetapool LpToken
    // The first argument is an array of inputAmounts, the second is for slippage
    // We do slippage control at the end of the batch operation which is why its 0 here
    _contracts.curveMetaPool.add_liquidity([destAmount, 0, 0], 0);
  }

  /**
   * @notice Burns crvLPToken to get intermediate swapToken
   * @param _amount The amount of lpTOken that get burned
   * @param _contracts ComponentDependencies (swapPool, curveMetapool and AngleRouter)
   * @param _i index of the component (0 == d3, 1 == 3eur)
   */
  function _withdrawFromCurve(
    uint256 _amount,
    ComponentDependencies memory _contracts,
    uint256 _i
  ) internal {
    // Burns lpToken to receive swapToken
    // First argument is the lpToken amount to burn, second is the index of the token we want to receive and third is slippage control
    _contracts.curveMetaPool.remove_liquidity_one_coin(_amount, 0, uint256(0));

    // No we trade the swapToken back to USDC
    uint256 amountReceived = swapToken[_i].balanceOf(address(this));
    if (_i == 0) {
      _contracts.swapPool.exchange_underlying(0, 2, amountReceived, 0);
    } else {
      _contracts.angleRouter.burn(
        address(this),
        amountReceived,
        0,
        address(swapToken[_i]),
        address(mintBatchTokens.sourceToken)
      );
    }
  }

  /**
   * @notice Deposits crvLPToken for yToken
   * @param _amount The amount of crvLPToken that get deposited
   * @param _yearnVault The yearn Vault in which we deposit
   */
  function _sendToYearn(uint256 _amount, YearnVault _yearnVault) internal {
    // Mints yToken and sends them to msg.sender (this contract)
    _yearnVault.deposit(_amount);
  }

  /**
   * @notice Withdraw crvLPToken from yearn
   * @param _amount The amount of crvLPToken which we deposit
   * @param _yearnVault The yearn Vault in which we deposit
   */
  function _withdrawFromYearn(uint256 _amount, YearnVault _yearnVault) internal {
    // Takes yToken and sends crvLPToken to this contract
    _yearnVault.withdraw(_amount);
  }

  /* ========== ADMIN ========== */

  /**
   * @notice This function allows the owner to change the composition of underlying token of the 3X
   * @param _components An array of addresses for the yToken needed to mint 3X
   * @param _componentDependencies An array structs describing underlying yToken, curveMetapool (which is also the lpToken), swapPool and AngleRouter
   */
  function setComponents(address[] memory _components, ComponentDependencies[] calldata _componentDependencies)
    external
    onlyRole(DAO_ROLE)
  {
    _setComponents(_components, _componentDependencies);
  }

  /**
   * @notice This function defines which underlying token and pools are needed to mint a 3X token
   * @param _components An array of addresses for the yToken needed to mint 3X
   * @param _componentDependencies An array structs describing underlying yToken, curveMetapool (which is also the lpToken), swapPool and AngleRouter
   * @dev since our calculations for minting just iterate through the index and match it with the quantities given by Set
   * @dev we must make sure to align them correctly by index, otherwise our whole calculation breaks down
   */
  function _setComponents(address[] memory _components, ComponentDependencies[] memory _componentDependencies)
    internal
  {
    emit ComponentDependenciesUpdated(_components, _componentDependencies);
    for (uint256 i; i < _components.length; i++) {
      componentDependencies[_components[i]] = _componentDependencies[i];
    }
  }

  function _getContract(bytes32 _name)
    internal
    view
    override(ACLAuth, KeeperIncentivized, ContractRegistryAccess)
    returns (address)
  {
    return super._getContract(_name);
  }
}
