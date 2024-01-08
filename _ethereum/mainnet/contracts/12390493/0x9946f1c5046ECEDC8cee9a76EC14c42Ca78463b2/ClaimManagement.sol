// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./ClaimConfig.sol";
import "./ICoverPool.sol";
import "./ICoverPoolFactory.sol";
import "./IClaimManagement.sol";

/**
 * @title Claim Management for claims filed for a COVER supported coverPool
 * @author Alan + crypto-pumpkin
 */
contract ClaimManagement is IClaimManagement, ClaimConfig {
  using SafeERC20 for IERC20;

  // the redeem delay for a cover when there is a pending claim
  uint256 public constant PENDING_CLAIM_REDEEM_DELAY = 10 days;
  // coverPool => nonce => Claim[]
  mapping(address => mapping(uint256 => Claim[])) private coverPoolClaims;

  constructor(
    address _feeCurrency,
    address _treasury,
    address _coverPoolFactory,
    address _defaultCVC
  ) {
    require(_feeCurrency != address(0), "CM: fee cannot be 0");
    require(_treasury != address(0), "CM: treasury cannot be 0");
    require(_coverPoolFactory != address(0), "CM: factory cannot be 0");
    require(_defaultCVC != address(0), "CM: defaultCVC cannot be 0");
    feeCurrency = IERC20(_feeCurrency);
    treasury = _treasury;
    coverPoolFactory = ICoverPoolFactory(_coverPoolFactory);
    defaultCVC = _defaultCVC;

    initializeOwner();
  }

  /// @notice File a claim for a Cover Pool, `_incidentTimestamp` must be within allowed time window
  function fileClaim(
    string calldata _coverPoolName,
    bytes32[] calldata _exploitRisks,
    uint48 _incidentTimestamp,
    string calldata _description,
    bool isForceFile
  ) external override {
    address coverPool = _getCoverPoolAddr(_coverPoolName);
    require(coverPool != address(0), "CM: pool not found");
    require(block.timestamp - _incidentTimestamp <= coverPoolFactory.defaultRedeemDelay() - TIME_BUFFER, "CM: time passed window");

    ICoverPool(coverPool).setNoclaimRedeemDelay(PENDING_CLAIM_REDEEM_DELAY);
    uint256 nonce = _getCoverPoolNonce(coverPool);
    uint256 claimFee = isForceFile ? forceClaimFee : getCoverPoolClaimFee(coverPool);
    feeCurrency.safeTransferFrom(msg.sender, address(this), claimFee);
    _updateCoverPoolClaimFee(coverPool);
    ClaimState state = isForceFile ? ClaimState.ForceFiled : ClaimState.Filed;
    coverPoolClaims[coverPool][nonce].push(Claim({
      filedBy: msg.sender,
      decidedBy: address(0),
      filedTimestamp: uint48(block.timestamp),
      incidentTimestamp: _incidentTimestamp,
      decidedTimestamp: 0,
      description: _description,
      state: state,
      feePaid: claimFee,
      payoutRiskList: _exploitRisks,
      payoutRates: new uint256[](_exploitRisks.length)
    }));
    emit ClaimUpdate(coverPool, state, nonce, coverPoolClaims[coverPool][nonce].length - 1);
  }

  /**
   * @notice Validates whether claim will be passed to CVC to decideClaim
   * @param _coverPool address: contract address of the coverPool that COVER supports
   * @param _nonce uint256: nonce of the coverPool
   * @param _index uint256: index of the claim
   * @param _claimIsValid bool: true if claim is valid and passed to CVC, false otherwise
   * Emits ClaimUpdate
   */
  function validateClaim(
    address _coverPool,
    uint256 _nonce,
    uint256 _index,
    bool _claimIsValid
  ) external override onlyOwner {
    Claim storage claim = coverPoolClaims[_coverPool][_nonce][_index];
    require(_index < coverPoolClaims[_coverPool][_nonce].length, "CM: bad index");
    require(_nonce == _getCoverPoolNonce(_coverPool), "CM: wrong nonce");
    require(claim.state == ClaimState.Filed, "CM: claim not filed");
    if (_claimIsValid) {
      claim.state = ClaimState.Validated;
      _resetCoverPoolClaimFee(_coverPool);
    } else {
      claim.state = ClaimState.Invalidated;
      claim.decidedTimestamp = uint48(block.timestamp);
      feeCurrency.safeTransfer(treasury, claim.feePaid);
      _resetNoclaimRedeemDelay(_coverPool, _nonce);
    }
    emit ClaimUpdate({
      coverPool: _coverPool,
      state: claim.state,
      nonce: _nonce,
      index: _index
    });
  }

  /// @notice Decide whether claim for a coverPool should be accepted(will payout) or denied, ignored _incidentTimestamp == 0
  function decideClaim(
    address _coverPool,
    uint256 _nonce,
    uint256 _index,
    uint48 _incidentTimestamp,
    bool _claimIsAccepted,
    bytes32[] calldata _exploitRisks,
    uint256[] calldata _payoutRates
  ) external override {
    require(_exploitRisks.length == _payoutRates.length, "CM: arrays len don't match");
    require(isCVCMember(_coverPool, msg.sender), "CM: !cvc");
    require(_nonce == _getCoverPoolNonce(_coverPool), "CM: wrong nonce");
    Claim storage claim = coverPoolClaims[_coverPool][_nonce][_index];
    require(claim.state == ClaimState.Validated || claim.state == ClaimState.ForceFiled, "CM: ! validated or forceFiled");
    if (_incidentTimestamp != 0) {
      require(claim.filedTimestamp - _incidentTimestamp <= coverPoolFactory.defaultRedeemDelay() - TIME_BUFFER, "CM: time passed window");
      claim.incidentTimestamp = _incidentTimestamp;
    }

    uint256 totalRates = _getTotalNum(_payoutRates);
    if (_claimIsAccepted && !_isDecisionWindowPassed(claim)) {
      require(totalRates > 0 && totalRates <= 1 ether, "CM: payout % not in (0%, 100%]");
      feeCurrency.safeTransfer(claim.filedBy, claim.feePaid);
      _resetCoverPoolClaimFee(_coverPool);
      claim.state = ClaimState.Accepted;
      claim.payoutRiskList = _exploitRisks;
      claim.payoutRates = _payoutRates;
      ICoverPool(_coverPool).enactClaim(claim.payoutRiskList, claim.payoutRates, claim.incidentTimestamp, _nonce);
    } else { // Max decision claim window passed, claim is default to Denied
      require(totalRates == 0, "CM: claim denied (default if passed window), but payoutNumerator != 0");
      feeCurrency.safeTransfer(treasury, claim.feePaid);
      claim.state = ClaimState.Denied;
    }
    _resetNoclaimRedeemDelay(_coverPool, _nonce);
    claim.decidedBy = msg.sender;
    claim.decidedTimestamp = uint48(block.timestamp);
    emit ClaimUpdate(_coverPool, claim.state, _nonce, _index);
  }

  function getCoverPoolClaims(address _coverPool, uint256 _nonce, uint256 _index) external view override returns (Claim memory) {
    return coverPoolClaims[_coverPool][_nonce][_index];
  }

  /// @notice Get all claims for coverPool `_coverPool` and nonce `_nonce` in state `_state`
  function getAllClaimsByState(address _coverPool, uint256 _nonce, ClaimState _state)
    external view override returns (Claim[] memory)
  {
    Claim[] memory allClaims = coverPoolClaims[_coverPool][_nonce];
    uint256 count;
    Claim[] memory temp = new Claim[](allClaims.length);
    for (uint i = 0; i < allClaims.length; i++) {
      if (allClaims[i].state == _state) {
        temp[count] = allClaims[i];
        count++;
      }
    }
    Claim[] memory claimsByState = new Claim[](count);
    for (uint i = 0; i < count; i++) {
      claimsByState[i] = temp[i];
    }
    return claimsByState;
  }

  /// @notice Get all claims for coverPool `_coverPool` and nonce `_nonce`
  function getAllClaimsByNonce(address _coverPool, uint256 _nonce) external view override returns (Claim[] memory) {
    return coverPoolClaims[_coverPool][_nonce];
  }

  /// @notice Get whether a pending claim for coverPool `_coverPool` and nonce `_nonce` exists
  function hasPendingClaim(address _coverPool, uint256 _nonce) public view override returns (bool) {
    Claim[] memory allClaims = coverPoolClaims[_coverPool][_nonce];
    for (uint i = 0; i < allClaims.length; i++) {
      ClaimState state = allClaims[i].state;
      if (state == ClaimState.Filed || state == ClaimState.ForceFiled || state == ClaimState.Validated) {
        return true;
      }
    }
    return false;
  }

  function _resetNoclaimRedeemDelay(address _coverPool, uint256 _nonce) private {
    if (hasPendingClaim(_coverPool, _nonce)) return;
    uint256 defaultRedeemDelay = coverPoolFactory.defaultRedeemDelay();
    ICoverPool(_coverPool).setNoclaimRedeemDelay(defaultRedeemDelay);
  }

  function _getCoverPoolAddr(string calldata _coverPoolName) private view returns (address) {
    return coverPoolFactory.coverPools(_coverPoolName);
  }

  function _getCoverPoolNonce(address _coverPool) private view returns (uint256) {
    return ICoverPool(_coverPool).claimNonce();
  }

  // The times passed since the claim was filed has to be less than the max claim decision window
  function _isDecisionWindowPassed(Claim memory claim) private view returns (bool) {
    return block.timestamp - claim.filedTimestamp > maxClaimDecisionWindow;
  }

  function _getTotalNum(uint256[] calldata _payoutRates) private pure returns (uint256 _totalRates) {
    for (uint256 i = 0; i < _payoutRates.length; i++) {
      _totalRates = _totalRates + _payoutRates[i];
    }
  }
} 