// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ContractRegistryAccess.sol";
import "./ACLAuth.sol";
import "./YearnVault.sol";
import "./BasicIssuanceModule.sol";
import "./ISetToken.sol";
import "./CurveContracts.sol";
import "./Curve3Pool.sol";
import "./IStaking.sol";

/*
 * @notice This contract allows users to mint and redeem Butter for using 3CRV, DAI, USDC, USDT
 * The Butter is created from several different yTokens which in turn need each a deposit of a crvLPToken.
 */
contract ButterWhaleProcessing is Pausable, ReentrancyGuard, ACLAuth, ContractRegistryAccess {
  using SafeERC20 for YearnVault;
  using SafeERC20 for ISetToken;
  using SafeERC20 for IERC20;

  /**
   * @param curveMetaPool A CurveMetaPool for trading an exotic stablecoin against 3CRV
   * @param crvLPToken The LP-Token of the CurveMetapool
   */
  struct CurvePoolTokenPair {
    CurveMetapool curveMetaPool;
    IERC20 crvLPToken;
  }

  /* ========== STATE VARIABLES ========== */

  bytes32 public immutable contractName = "ButterWhaleProcessing";

  IContractRegistry public contractRegistry;
  IStaking public staking;
  ISetToken public setToken;
  IERC20 public threeCrv;
  Curve3Pool private threePool;
  BasicIssuanceModule public setBasicIssuanceModule;
  mapping(address => CurvePoolTokenPair) public curvePoolTokenPairs;
  uint256 public redemptionFees;
  uint256 public redemptionFeeRate;
  address public feeRecipient;

  mapping(address => bool) public sweethearts;

  /* ========== EVENTS ========== */
  event Minted(address account, uint256 amount, uint256 butterAmount);
  event Redeemed(address account, uint256 amount, uint256 claimableTokenBalance);
  event ZapMinted(address account, uint256 mintAmount, uint256 butterAmount);
  event ZapRedeemed(address account, uint256 redeemAmount, uint256 claimableTokenBalance);
  event CurveTokenPairsUpdated(address[] yTokenAddresses, CurvePoolTokenPair[] curveTokenPairs);
  event RedemptionFeeUpdated(uint256 newRedemptionFee, address newFeeRecipient);
  event SweetheartUpdated(address sweetheart, bool isSweeheart);
  event StakingUpdated(address beforeAddress, address afterAddress);

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry _contractRegistry,
    IStaking _staking,
    ISetToken _setToken,
    IERC20 _threeCrv,
    Curve3Pool _threePool,
    BasicIssuanceModule _basicIssuanceModule,
    address[] memory _yTokenAddresses,
    CurvePoolTokenPair[] memory _curvePoolTokenPairs
  ) ContractRegistryAccess(_contractRegistry) {
    contractRegistry = _contractRegistry;
    staking = _staking;
    setToken = _setToken;
    threeCrv = _threeCrv;
    threePool = _threePool;
    setBasicIssuanceModule = _basicIssuanceModule;

    _setCurvePoolTokenPairs(_yTokenAddresses, _curvePoolTokenPairs);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Mint Butter token with deposited 3CRV. This function goes through all the steps necessary to mint an optimal amount of Butter
   * @param _amount Amount of 3cr3CRV to use for minting
   * @param _slippage The accepted slippage in basis points.
   * @param _stake Do you want to stake your minted Butter?
   * @dev This function deposits 3CRV in the underlying Metapool and deposits these LP token to get yToken which in turn are used to mint Butter
   */
  function mint(
    uint256 _amount,
    uint256 _slippage,
    bool _stake
  ) external whenNotPaused {
    require(threeCrv.balanceOf(msg.sender) >= _amount, "insufficent balance");
    threeCrv.transferFrom(msg.sender, address(this), _amount);
    uint256 butterAmount = _mint(_amount, _slippage, _stake);
    emit Minted(msg.sender, _amount, butterAmount);
  }

  /**
   * @notice Redeems Butter for 3CRV. This function goes through all the steps necessary to get 3CRV
   * @param _amount amount of Butter to be redeemed
   * @param _slippage The accepted slippage in basis points.
   * @dev This function reedeems Butter for the underlying yToken and deposits these yToken in curve Metapools for 3CRV
   */
  function redeem(uint256 _amount, uint256 _slippage) external whenNotPaused {
    uint256 claimableTokenBalance = _redeem(_amount, _slippage);
    threeCrv.safeTransfer(msg.sender, claimableTokenBalance);
    emit Redeemed(msg.sender, _amount, claimableTokenBalance);
  }

  /**
   * @notice zapMint allows a user to mint Butter directly with stablecoins
   * @param _amounts An array of amounts in stablecoins the user wants to deposit
   * @param _min_3crv_amount The min amount of 3CRV which should be minted by the curve three-pool (slippage control)
   * @param _slippage The accepted slippage in basis points.
   * @param _stake Do you want to stake your minted butter?
   * @dev The amounts in _amounts must align with their index in the curve three-pool
   */
  function zapMint(
    uint256[3] memory _amounts,
    uint256 _min_3crv_amount,
    uint256 _slippage,
    bool _stake
  ) external whenNotPaused {
    for (uint256 i; i < _amounts.length; i++) {
      if (_amounts[i] > 0) {
        //Deposit Stables
        IERC20(threePool.coins(uint256(i))).safeTransferFrom(msg.sender, address(this), _amounts[i]);
      }
    }
    //Deposit stables to receive 3CRV
    threePool.add_liquidity(_amounts, _min_3crv_amount);

    //Check the amount of returned 3CRV
    /*
    While curves metapools return the amount of minted 3CRV this is not possible with the three-pool which is why we simply have to check our balance after depositing our stables.
    If a user sends 3CRV to this contract by accident (Which cant be retrieved anyway) they will be used aswell.
    */
    uint256 threeCrvAmount = threeCrv.balanceOf(address(this));
    uint256 butterAmount = _mint(threeCrvAmount, _slippage, _stake);
    emit ZapMinted(msg.sender, threeCrvAmount, butterAmount);
  }

  /**
   * @notice zapRedeem allows a user to claim their processed 3CRV from a redeemBatch and directly receive stablecoins
   * @param _amount amount of Butter to be redeemed
   * @param _stableCoinIndex Defines which stablecoin the user wants to receive
   * @param _min_stable_amount The min amount of stables which should be returned by the curve three-pool (slippage control)
   * @param _slippage The accepted slippage in basis points.
   * @dev The _stableCoinIndex must align with the index in the curve three-pool
   */
  function zapRedeem(
    uint256 _amount,
    uint256 _stableCoinIndex,
    uint256 _min_stable_amount,
    uint256 _slippage
  ) external whenNotPaused {
    uint256 claimableTokenBalance = _redeem(_amount, _slippage);
    _swapAndTransfer3Crv(claimableTokenBalance, _stableCoinIndex, _min_stable_amount);
    emit ZapRedeemed(msg.sender, _amount, claimableTokenBalance);
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

      _maxApprove(threeCrv, address(curveMetapool));
      _maxApprove(curveLpToken, address(yearnVault));
      _maxApprove(curveLpToken, address(curveMetapool));
    }
    for (uint128 i; i < 3; i++) {
      _maxApprove(IERC20(threePool.coins(i)), address(threePool));
    }
    _maxApprove(threeCrv, address(threePool));
    _maxApprove(setToken, address(staking));
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

  function _mint(
    uint256 _amount,
    uint256 _slippage,
    bool _stake
  ) internal returns (uint256) {
    //Get the quantities of yToken needed to mint 1 BTR (This should be an equal amount per Token)
    (address[] memory tokenAddresses, uint256[] memory quantities) = setBasicIssuanceModule
      .getRequiredComponentUnitsForIssue(setToken, 1e18);

    //The value of 1 BTR in virtual Price (`quantities` * `virtualPrice`)
    uint256 setValue = valueOfComponents(tokenAddresses, quantities);

    uint256 threeCrvValue = threePool.get_virtual_price();

    //Had to add this to combat a weird "stack to deep" issue when just passing _amount in _getPoolAllocationAndRatio
    uint256 batchValue = valueOf3Crv(_amount);

    //Remaining amount of 3CRV in this batch which hasnt been allocated yet
    uint256 remainingBatchBalanceValue = batchValue;

    //Temporary allocation of 3CRV to be deployed in curveMetapools
    uint256[] memory poolAllocations = new uint256[](quantities.length);

    //Ratio of 3CRV needed to mint 1 BTR
    uint256[] memory ratios = new uint256[](quantities.length);

    for (uint256 i; i < tokenAddresses.length; i++) {
      // prettier-ignore
      (uint256 allocation, uint256 ratio) = _getPoolAllocationAndRatio(tokenAddresses[i], quantities[i], batchValue, setValue);
      poolAllocations[i] = allocation;
      ratios[i] = ratio;
      remainingBatchBalanceValue -= allocation;
    }

    for (uint256 i; i < tokenAddresses.length; i++) {
      uint256 poolAllocation;

      //RemainingLeftovers should only be 0 if there were no yToken leftover from previous batches
      //since the first iteration of poolAllocation uses all 3CRV. Therefore we can only have `remainingBatchBalanceValue` from subtracted leftovers
      if (remainingBatchBalanceValue > 0) {
        poolAllocation = _getPoolAllocation(remainingBatchBalanceValue, ratios[i]);
      }

      //Pool 3CRV to get crvLPToken
      _sendToCurve(
        ((poolAllocation + poolAllocations[i]) * 1e18) / threeCrvValue,
        curvePoolTokenPairs[tokenAddresses[i]].curveMetaPool
      );

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

    require(butterAmount >= getMinAmountToMint(batchValue, setValue, _slippage), "slippage too high");

    //Mint Butter
    if (_stake) {
      setBasicIssuanceModule.issue(setToken, butterAmount, address(this));
      staking.stakeFor(butterAmount, msg.sender);
    } else {
      setBasicIssuanceModule.issue(setToken, butterAmount, msg.sender);
    }

    return butterAmount;
  }

  function _redeem(uint256 _amount, uint256 _slippage) internal returns (uint256) {
    require(setToken.balanceOf(msg.sender) >= _amount, "insufficient balance");
    setToken.transferFrom(msg.sender, address(this), _amount);

    //Get tokenAddresses for mapping of underlying
    (address[] memory tokenAddresses, uint256[] memory quantities) = setBasicIssuanceModule
      .getRequiredComponentUnitsForIssue(setToken, _amount);

    //Allow setBasicIssuanceModule to use Butter
    _setBasicIssuanceModuleAllowance(_amount);

    //Redeem Butter for yToken
    setBasicIssuanceModule.redeem(setToken, _amount, address(this));

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
    uint256 claimableTokenBalance = threeCrv.balanceOf(address(this)) - oldBalance;

    require(
      claimableTokenBalance >= getMinAmount3CrvFromRedeem(valueOfComponents(tokenAddresses, quantities), _slippage),
      "slippage too high"
    );
    if (!sweethearts[msg.sender]) {
      //Fee is deducted from threeCrv -- This allows it to work with the Zapper
      //Fes are denominated in BasisPoints
      uint256 fee = (claimableTokenBalance * redemptionFeeRate) / 10_000;
      redemptionFees = redemptionFees + fee;
      claimableTokenBalance = claimableTokenBalance - fee;
    }
    return claimableTokenBalance;
  }

  /**
   * @notice sets max allowance given a token and a spender
   * @param _token the token which gets approved to be spend
   * @param _spender the spender which gets a max allowance to spend `_token`
   */
  function _maxApprove(IERC20 _token, address _spender) internal {
    _token.safeApprove(_spender, 0);
    _token.safeApprove(_spender, type(uint256).max);
  }

  /**
   * @notice sets allowance for basic issuance module
   * @param _amount amount to approve
   */
  function _setBasicIssuanceModuleAllowance(uint256 _amount) internal {
    setToken.safeApprove(address(setBasicIssuanceModule), 0);
    setToken.safeApprove(address(setBasicIssuanceModule), _amount);
  }

  function _getPoolAllocationAndRatio(
    address _component,
    uint256 _quantity,
    uint256 _batchValue,
    uint256 _setValue
  ) internal view returns (uint256 poolAllocation, uint256 ratio) {
    //Calculate the virtualPrice of one yToken
    uint256 componentValuePerShare = (YearnVault(_component).pricePerShare() *
      curvePoolTokenPairs[_component].curveMetaPool.get_virtual_price()) / 1e18;

    //Calculate the value of quantity (of yToken) in virtualPrice
    uint256 componentValuePerSet = (_quantity * componentValuePerShare) / 1e18;

    //Calculate the value of leftover yToken in virtualPrice
    uint256 componentValueHeldByContract = (YearnVault(_component).balanceOf(address(this)) * componentValuePerShare) /
      1e18;

    ratio = (componentValuePerSet * 1e18) / _setValue;

    poolAllocation = _getPoolAllocation(_batchValue, ratio) - componentValueHeldByContract;

    return (poolAllocation, ratio);
  }

  /**
   * @notice returns the amount of 3CRV that should be allocated for a curveMetapool
   * @param _balance the max amount of 3CRV that is available in this iteration
   * @param _ratio the ratio of 3CRV needed to get enough yToken to mint butter
   */
  function _getPoolAllocation(uint256 _balance, uint256 _ratio) internal pure returns (uint256) {
    return ((_balance * _ratio) / 1e18);
  }

  /**
   * @notice _swapAndTransfer3Crv burns 3CRV and sends the returned stables to the user
   * @param _threeCurveAmount How many 3CRV shall be burned
   * @param _stableCoinIndex Defines which stablecoin the user wants to receive
   * @param _min_amount The min amount of stables which should be returned by the curve three-pool (slippage control)
   * @dev The stableCoinIndex_ must align with the index in the curve three-pool
   */
  function _swapAndTransfer3Crv(
    uint256 _threeCurveAmount,
    uint256 _stableCoinIndex,
    uint256 _min_amount
  ) internal {
    //Burn 3CRV to receive stables
    threePool.remove_liquidity_one_coin(_threeCurveAmount, int128(uint128(_stableCoinIndex)), _min_amount);

    //Check the amount of returned stables
    /*
    If a user sends Stables to this contract by accident (Which cant be retrieved anyway) they will be used aswell.
    */
    uint256 stableBalance = IERC20(threePool.coins(_stableCoinIndex)).balanceOf(address(this));

    //Transfer stables to user
    IERC20(threePool.coins(_stableCoinIndex)).safeTransfer(msg.sender, stableBalance);
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

  /* ========== ADMIN ========== */

  /**
   * @notice This function allows the owner to change the composition of underlying token of the Butter
   * @param _yTokenAddresses An array of addresses for the yToken needed to mint Butter
   * @param _curvePoolTokenPairs An array structs describing underlying yToken, crvToken and curve metapool
   */
  function setCurvePoolTokenPairs(address[] memory _yTokenAddresses, CurvePoolTokenPair[] calldata _curvePoolTokenPairs)
    public
    onlyRole(DAO_ROLE)
  {
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
   * @notice Changes the redemption fee rate and the fee recipient
   * @param _feeRate Redemption fee rate in basis points
   * @param _recipient The recipient which receives these fees (Should be DAO treasury)
   * @dev Per default both of these values are not set. Therefore a fee has to be explicitly be set with this function
   */
  function setRedemptionFee(uint256 _feeRate, address _recipient) external onlyRole(DAO_ROLE) {
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
   * @notice Allows the DAO to recover leftover yToken that have accumulated between pages and cant be used effectively in upcoming batches
   * @dev This should only be used if there is a clear trend that a certain amount of yToken leftover wont be used in the minting process
   * @param _yTokenAddress address of the yToken that should be recovered
   * @param _amount amount of yToken that should recovered
   */
  function recoverLeftover(address _yTokenAddress, uint256 _amount) external onlyRole(DAO_ROLE) {
    require(address(curvePoolTokenPairs[_yTokenAddress].curveMetaPool) != address(0), "yToken doesnt exist");
    IERC20(_yTokenAddress).safeTransfer(_getContract(keccak256("Treasury")), _amount);
  }

  /**
   * @notice Toggles an address as Sweetheart (partner addresses that don't pay a redemption fee)
   * @param _sweetheart The address that shall become/lose their sweetheart status
   */
  function updateSweetheart(address _sweetheart, bool _enabled) external onlyRole(DAO_ROLE) {
    sweethearts[_sweetheart] = _enabled;
    emit SweetheartUpdated(_sweetheart, _enabled);
  }

  function setStaking(address _staking) external onlyRole(DAO_ROLE) {
    emit StakingUpdated(address(staking), _staking);
    staking = IStaking(_staking);
  }

  /**
   * @notice Pauses the contract.
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function pause() external onlyRole(DAO_ROLE) {
    _pause();
  }

  /**
   * @notice Unpauses the contract.
   * @dev All function with the modifer `whenNotPaused` cant be called anymore. Namly deposits and mint/redeem
   */
  function unpause() external onlyRole(DAO_ROLE) {
    _unpause();
  }

  function _getContract(bytes32 _name) internal view override(ACLAuth, ContractRegistryAccess) returns (address) {
    return super._getContract(_name);
  }
}
