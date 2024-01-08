// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Clones.sol";
import "./Create2.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./StringHelper.sol";
import "./ICover.sol";
import "./ICoverERC20.sol";
import "./IOwnable.sol";
import "./ICoverPool.sol";
import "./ICoverPoolFactory.sol";
import "./ICovTokenProxy.sol";

/**
 * @title Cover contract
 * @author crypto-pumpkin
 *  - Holds collateral funds
 *  - Mints and burns CovTokens (CoverERC20)
 *  - Handles redeem with or without an accepted claim
 */
contract Cover is ICover, Initializable, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;

  uint256 public override constant BASE_SCALE = 1e18;

  bool public override deployComplete; // once true, never false
  uint48 public override expiry;
  address public override collateral;
  ICoverERC20 public override noclaimCovToken;
  string public override name; // Yearn_0_DAI_12_31_21
  uint256 public override feeRate; // BASE_SCALE, cannot be changed
  uint256 public override mintRatio; // BASE_SCALE, cannot be changed, 1 collateral mint mintRatio * 1 covTokens
  uint256 public override totalCoverage; // in covTokens
  uint256 public override claimNonce;

  ICoverERC20[] public override futureCovTokens;
  mapping(bytes32 => ICoverERC20) public override claimCovTokenMap;
  // future token => CLAIM Token
  mapping(ICoverERC20 => ICoverERC20) public override futureCovTokenMap;

  modifier onlyNotPaused() {
    require(!_factory().paused(), "Cover: paused");
    _;
  }

  /// @dev Initialize, called once
  function initialize (
    string calldata _name,
    uint48 _expiry,
    address _collateral,
    uint256 _mintRatio,
    uint256 _claimNonce
  ) public initializer {
    initializeOwner();
    name = _name;
    expiry = _expiry;
    collateral = _collateral;
    mintRatio = _mintRatio;
    claimNonce = _claimNonce;
    uint256 yearlyFeeRate = _factory().yearlyFeeRate();
    feeRate = yearlyFeeRate * (uint256(_expiry) - block.timestamp) / 365 days;

    noclaimCovToken = _createCovToken("NC_");
    if (_coverPool().extendablePool()) {
      futureCovTokens.push(_createCovToken("C_FUT0_"));
    }
    deploy();
  }

  /// @notice only CoverPool can mint, collateral is transfered in CoverPool
  function mint(uint256 _receivedColAmt, address _receiver) external override onlyOwner nonReentrant {
    require(deployComplete, "Cover: deploy incomplete");
    ICoverPool coverPool = _coverPool();
    require(coverPool.claimNonce() == claimNonce, "Cover: nonces dont match");

    // mintAmount has same decimals of covTokens == collateral decimals
    uint256 mintAmount = _receivedColAmt * mintRatio / BASE_SCALE;
    totalCoverage = totalCoverage + mintAmount;

    (bytes32[] memory _riskList) = coverPool.getRiskList();
    for (uint i = 0; i < _riskList.length; i++) {
      claimCovTokenMap[_riskList[i]].mint(_receiver, mintAmount);
    }
    noclaimCovToken.mint(_receiver, mintAmount);
    _handleLatestFutureToken(_receiver, mintAmount, true /* mint */);
  }

  /// @notice normal redeem (no claim accepted), but always allow redeem back collateral with all covTokens (must converted all eligible future token to claim tokens)
  function redeem(uint256 _amount) external override nonReentrant onlyNotPaused {
    ICoverPool coverPool = _coverPool();

    if (coverPool.claimNonce() > claimNonce) { // accepted claim, should only redeem for not affected cover
      ICoverPool.ClaimDetails memory claim = _claimDetails();
      uint256 defaultRedeemDelay = _factory().defaultRedeemDelay();
      if (claim.incidentTimestamp > expiry && block.timestamp >= uint256(expiry) + defaultRedeemDelay) {
        // not affected cover, default delay passed, redeem with noclaim tokens only
        _burnNoclaimAndPay(_amount);
      } else { // redeem with all covTokens is always allowed
        _redeemWithAllCovTokens(coverPool, _amount);
      }
    } else if (block.timestamp >= uint256(expiry) + coverPool.noclaimRedeemDelay()) {
      // no accepted claim, expired and noclaim delay passed, redeem with noclaim tokens only. Use noclaimRedeemDelay (>= default delay) in case there are pending claims
      _burnNoclaimAndPay(_amount);
    } else { // redeem with all covTokens is always allowed
      _redeemWithAllCovTokens(coverPool, _amount);
    }
    emit Redeemed('Normal', msg.sender, _amount);
  }

  /**
   * @notice convert future tokens to associated CLAIM tokens and next future tokens
   * Once a new risk is added into the CoverPool, the latest futureToken can be converted to the related CLAIM Token and next futureToken (both are created while adding risk to the pool).
   * @dev Never covert the lastest future tokens, it will revert
   */
  function convert(ICoverERC20[] calldata _futureTokens) external override onlyNotPaused {
    for (uint256 i = 0; i < _futureTokens.length; i++) {
      _convert(_futureTokens[i]);
    }
  }

  /**
   * @notice called by owner (CoverPool) only, when a new risk is added to pool the first time
   * - create a new claim token for risk
   * - point the current latest (last one in futureCovTokens) future token to newly created claim token
   * - create a new future token and push to futureCovTokens
   */
  function addRisk(bytes32 _risk) external override onlyOwner {
    if (block.timestamp >= expiry) return;
    // if risk is added, return, so owner (CoverPool) can continue
    if (address(claimCovTokenMap[_risk]) != address(0)) return;

    ICoverERC20[] memory futureCovTokensCopy = futureCovTokens;
    uint256 len = futureCovTokensCopy.length;
    ICoverERC20 latestFutureCovToken = futureCovTokensCopy[len - 1];

    string memory riskName = StringHelper.bytes32ToString(_risk);
    ICoverERC20 claimToken = _createCovToken(string(abi.encodePacked("C_", riskName, "_")));
    claimCovTokenMap[_risk] = claimToken;
    futureCovTokenMap[latestFutureCovToken] = claimToken;

    string memory nextFutureTokenName = string(abi.encodePacked("C_FUT", StringHelper.uintToString(len), "_"));
    futureCovTokens.push(_createCovToken(nextFutureTokenName));
  }

  /// @notice redeem when there is an accepted claim
  function redeemClaim() external override nonReentrant onlyNotPaused {
    ICoverPool coverPool = _coverPool();
    require(coverPool.claimNonce() > claimNonce, "Cover: no claim accepted");
    ICoverPool.ClaimDetails memory claim = _claimDetails();
    require(claim.incidentTimestamp <= expiry, "Cover: not eligible");
    uint256 defaultRedeemDelay = _factory().defaultRedeemDelay();
    require(block.timestamp >= uint256(claim.claimEnactedTimestamp) + defaultRedeemDelay, "Cover: not ready");

    // get all claim tokens eligible amount to payout
    uint256 eligibleAmount;
    for (uint256 i = 0; i < claim.payoutRiskList.length; i++) {
      ICoverERC20 covToken = claimCovTokenMap[claim.payoutRiskList[i]];
      uint256 amount = covToken.balanceOf(msg.sender);
      if (amount > 0) {
        eligibleAmount = eligibleAmount + amount * claim.payoutRates[i] / BASE_SCALE;
        covToken.burnByCover(msg.sender, amount);
      }
    }

    // if total claim payout rate < 1, get noclaim token eligible amount to payout
    if (claim.totalPayoutRate < BASE_SCALE) {
      uint256 amount = noclaimCovToken.balanceOf(msg.sender);
      if (amount > 0) {
        uint256 payoutAmount = amount * (BASE_SCALE - claim.totalPayoutRate) / BASE_SCALE;
        eligibleAmount = eligibleAmount + payoutAmount;
        noclaimCovToken.burnByCover(msg.sender, amount);
      }
    }

    require(eligibleAmount > 0, "Cover: low covToken balance");
    _payCollateral(msg.sender, eligibleAmount);
    emit Redeemed('Claim', msg.sender, eligibleAmount);
  }

  /// @notice multi-tx/block deployment solution. Only called (1+ times depend on size of pool) at creation. Deploy covTokens as many as possible in one tx till not enough gas left.
  function deploy() public override {
    require(!deployComplete, "Cover: deploy completed");
    (bytes32[] memory _riskList) = _coverPool().getRiskList();
    uint256 startGas = gasleft();
    for (uint256 i = 0; i < _riskList.length; i++) {
      if (startGas < _factory().deployGasMin()) return;
      ICoverERC20 claimToken = claimCovTokenMap[_riskList[i]];
      if (address(claimToken) == address(0)) {
        string memory riskName = StringHelper.bytes32ToString(_riskList[i]);
        claimToken = _createCovToken(string(abi.encodePacked("C_", riskName, "_")));
        claimCovTokenMap[_riskList[i]] = claimToken;
        startGas = gasleft();
      }
    }
    deployComplete = true;
    emit CoverDeployCompleted();
  }

  /// @notice coverageAmt is not respected if there is a claim
  function viewRedeemable(address _account, uint256 _coverageAmt) external view override returns (uint256 redeemableAmt) {
    ICoverPool coverPool = _coverPool();
    if (coverPool.claimNonce() == claimNonce) {
      IERC20 colToken = IERC20(collateral);
      uint256 colBal = colToken.balanceOf(address(this));
      uint256 payoutColAmt = _coverageAmt * BASE_SCALE / mintRatio;
      uint256 payoutColAmtAfterFees = payoutColAmt - payoutColAmt * feeRate / BASE_SCALE;
      redeemableAmt = colBal > payoutColAmtAfterFees ? payoutColAmtAfterFees : colBal;
    } else {
      ICoverPool.ClaimDetails memory claim = _claimDetails();
      for (uint256 i = 0; i < claim.payoutRiskList.length; i++) {
        ICoverERC20 covToken = claimCovTokenMap[claim.payoutRiskList[i]];
        uint256 amount = covToken.balanceOf(_account);
        redeemableAmt = redeemableAmt + amount * claim.payoutRates[i] / BASE_SCALE;
      }
      if (claim.totalPayoutRate < BASE_SCALE) {
        uint256 amount = noclaimCovToken.balanceOf(_account);
        uint256 payoutAmount = amount * (BASE_SCALE - claim.totalPayoutRate) / BASE_SCALE;
        redeemableAmt = redeemableAmt + payoutAmount;
      }
    }
  }

  function getCovTokens() external view override
    returns (
      ICoverERC20 _noclaimCovToken,
      ICoverERC20[] memory _claimCovTokens,
      ICoverERC20[] memory _futureCovTokens)
  {
    (bytes32[] memory _riskList) = _coverPool().getRiskList();
    ICoverERC20[] memory claimCovTokens = new ICoverERC20[](_riskList.length);
    for (uint256 i = 0; i < _riskList.length; i++) {
      claimCovTokens[i] = ICoverERC20(claimCovTokenMap[_riskList[i]]);
    }
    return (noclaimCovToken, claimCovTokens, futureCovTokens);
  }

  /// @notice collectFees send fees to treasury, anyone can call
  function collectFees() public override {
    IERC20 colToken = IERC20(collateral);
    uint256 collateralBal = colToken.balanceOf(address(this));
    if (collateralBal == 0) return;
    if (totalCoverage == 0) {
      colToken.safeTransfer(_factory().treasury(), collateralBal);
    } else {
      uint256 totalCoverageInCol = totalCoverage * BASE_SCALE / mintRatio;
      uint256 feesInTheory = totalCoverageInCol * feeRate / BASE_SCALE;
      if (collateralBal > totalCoverageInCol - feesInTheory) {
        uint256 feesToCollect = feesInTheory + collateralBal - totalCoverageInCol;
        colToken.safeTransfer(_factory().treasury(), feesToCollect);
      }
    }
  }

  // transfer collateral (amount - fee) from this contract to recevier
  function _payCollateral(address _receiver, uint256 _coverageAmt) private {
    collectFees();
    totalCoverage = totalCoverage - _coverageAmt;

    IERC20 colToken = IERC20(collateral);
    uint256 colBal = colToken.balanceOf(address(this));
    uint256 payoutColAmt = _coverageAmt * BASE_SCALE / mintRatio;
    uint256 payoutColAmtAfterFees = payoutColAmt - payoutColAmt * feeRate / BASE_SCALE;
    if (colBal > payoutColAmtAfterFees) {
      colToken.safeTransfer(_receiver, payoutColAmtAfterFees);
    } else {
      colToken.safeTransfer(_receiver, colBal);
    }
  }

  // must convert all future tokens to claim tokens to be able to redeem with all covTokens
  function _redeemWithAllCovTokens(ICoverPool coverPool, uint256 _amount) private {
    noclaimCovToken.burnByCover(msg.sender, _amount);
    _handleLatestFutureToken(msg.sender, _amount, false /* burn */);

    (bytes32[] memory riskList) = coverPool.getRiskList();
    for (uint i = 0; i < riskList.length; i++) {
      claimCovTokenMap[riskList[i]].burnByCover(msg.sender, _amount);
    }
    _payCollateral(msg.sender, _amount);
  }

  // note: futureCovTokens can be [] if the pool is not expendable. In that case, nothing to do.
  function _handleLatestFutureToken(address _receiver, uint256 _amount, bool _isMint) private {
    ICoverERC20[] memory futureCovTokensCopy = futureCovTokens;
    uint256 len = futureCovTokensCopy.length;
    if (len == 0) return;
    ICoverERC20 latestFutureCovToken = futureCovTokensCopy[len - 1];
    _isMint
      ? latestFutureCovToken.mint(_receiver, _amount)
      : latestFutureCovToken.burnByCover(_receiver, _amount);
  }

  // burn noclaim covToken and pay sender
  function _burnNoclaimAndPay(uint256 _amount) private {
    noclaimCovToken.burnByCover(msg.sender, _amount);
    _payCollateral(msg.sender, _amount);
  }

  // convert the future token to claim token and mint next future token
  function _convert(ICoverERC20 _futureToken) private {
    ICoverERC20 claimCovToken = futureCovTokenMap[_futureToken];
    require(address(claimCovToken) != address(0), "Cover: nothing to convert");
    uint256 amount = _futureToken.balanceOf(msg.sender);
    require(amount > 0, "Cover: insufficient balance");
    _futureToken.burnByCover(msg.sender, amount);
    claimCovToken.mint(msg.sender, amount);
    emit FutureTokenConverted(address(_futureToken), address(claimCovToken), amount);

    // mint next future covTokens (the last future token points to no tokens)
    ICoverERC20[] memory futureCovTokensCopy = futureCovTokens;
    for (uint256 i = 0; i < futureCovTokensCopy.length - 1; i++) {
      if (futureCovTokensCopy[i] == _futureToken) {
        ICoverERC20 futureCovToken = futureCovTokensCopy[i + 1];
        futureCovToken.mint(msg.sender, amount);
        return;
      }
    }
  }

  /// @dev Emits CovTokenCreated
  function _createCovToken(string memory _prefix) private returns (ICoverERC20) {
    uint8 decimals = uint8(IERC20(collateral).decimals());
    require(decimals > 0, "Cover: col decimals is 0");

    address coverERC20Impl = _factory().coverERC20Impl();
    bytes32 salt = keccak256(abi.encodePacked(_coverPool().name(), expiry, collateral, claimNonce, _prefix));
    address proxyAddr = Clones.cloneDeterministic(coverERC20Impl, salt);
    ICovTokenProxy(proxyAddr).initialize("Cover Protocol covToken", string(abi.encodePacked(_prefix, name)), decimals);

    emit CovTokenCreated(proxyAddr);
    return ICoverERC20(proxyAddr);
  }

  function _coverPool() private view returns (ICoverPool) {
    return ICoverPool(owner());
  }

  // the owner of this contract is CoverPool, the owner of CoverPool is CoverPoolFactory contract
  function _factory() private view returns (ICoverPoolFactory) {
    return ICoverPoolFactory(IOwnable(owner()).owner());
  }

  // get the claim details for the corresponding nonce from coverPool contract
  function _claimDetails() private view returns (ICoverPool.ClaimDetails memory) {
    return _coverPool().getClaimDetails(claimNonce);
  }
}