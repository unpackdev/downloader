// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IClaimConfig.sol";
import "./ICoverPool.sol";
import "./ICoverPoolFactory.sol";

/**
 * @title Config for ClaimManagement contract
 * @author Alan + crypto-pumpkin
 */
contract ClaimConfig is IClaimConfig, Ownable {

  IERC20 public override feeCurrency;
  address public override treasury;
  ICoverPoolFactory public override coverPoolFactory;
  address public override defaultCVC; // if not specified, default to this

  uint256 internal constant TIME_BUFFER = 1 hours;
  // The max time allowed from filing a claim to a decision made, 1 hr buffer for calling
  uint256 public override maxClaimDecisionWindow = 7 days - TIME_BUFFER;
  uint256 public override baseClaimFee = 50e18;
  uint256 public override forceClaimFee = 500e18;
  uint256 public override feeMultiplier = 2;

  // coverPool => claim fee
  mapping(address => uint256) private coverPoolClaimFee;
  // coverPool => cvc addresses
  mapping(address => address[]) public override cvcMap;

  function setTreasury(address _treasury) external override onlyOwner {
    require(_treasury != address(0), "CC: treasury cannot be 0");
    treasury = _treasury;
  }

  /// @notice Set max time window allowed to decide a claim after filed
  function setMaxClaimDecisionWindow(uint256 _newTimeWindow) external override onlyOwner {
    require(_newTimeWindow > 0, "CC: window too short");
    maxClaimDecisionWindow = _newTimeWindow;
  }

  function setDefaultCVC(address _cvc) external override onlyOwner {
    require(_cvc != address(0), "CC: default CVC cannot be 0");
    defaultCVC = _cvc;
  }

  /// @notice Add CVC groups for multiple coverPools
  function addCVCForPools(address[] calldata _coverPools, address[] calldata _cvcs) external override onlyOwner {
    require(_coverPools.length == _cvcs.length, "CC: lengths don't match");
    for (uint256 i = 0; i < _coverPools.length; i++) {
      _addCVCForPool(_coverPools[i], _cvcs[i]);
    }
  }

  /// @notice Remove CVC groups for multiple coverPools
  function removeCVCForPools(address[] calldata _coverPools, address[] calldata _cvcs) external override onlyOwner {
    require(_coverPools.length == _cvcs.length, "CC: lengths don't match");
    for (uint256 i = 0; i < _coverPools.length; i++) {
      _removeCVCForPool(_coverPools[i], _cvcs[i]);
    }
  }

  function setFeeAndCurrency(uint256 _baseClaimFee, uint256 _forceClaimFee, address _currency) external override onlyOwner {
    require(_currency != address(0), "CC: feeCurrency cannot be 0");
    require(_baseClaimFee > 0, "CC: baseClaimFee <= 0");
    require(_forceClaimFee > _baseClaimFee, "CC: force Fee <= base Fee");
    baseClaimFee = _baseClaimFee;
    forceClaimFee = _forceClaimFee;
    feeCurrency = IERC20(_currency);
  }

  function setFeeMultiplier(uint256 _multiplier) external override onlyOwner {
    require(_multiplier >= 1, "CC: multiplier must be >= 1");
    feeMultiplier = _multiplier;
  }

  /// @notice return the whole list so dont need to query by index
  function getCVCList(address _coverPool) external view override returns (address[] memory) {	
    return cvcMap[_coverPool];	
  }

  function isCVCMember(address _coverPool, address _address) public view override returns (bool) {
    address[] memory cvcCopy = cvcMap[_coverPool];
    if (cvcCopy.length == 0 && _address == defaultCVC) return true;
    for (uint256 i = 0; i < cvcCopy.length; i++) {
      if (_address == cvcCopy[i]) {
        return true;
      }
    }
    return false;
  }

  function getCoverPoolClaimFee(address _coverPool) public view override returns (uint256) {
    return coverPoolClaimFee[_coverPool] < baseClaimFee ? baseClaimFee : coverPoolClaimFee[_coverPool];
  }

  // Add CVC group for a coverPool if `_cvc` isn't already added
  function _addCVCForPool(address _coverPool, address _cvc) private onlyOwner {
    address[] memory cvcCopy = cvcMap[_coverPool];
    for (uint256 i = 0; i < cvcCopy.length; i++) {
      require(cvcCopy[i] != _cvc, "CC: cvc exists");
    }
    cvcMap[_coverPool].push(_cvc);
  }

  function _removeCVCForPool(address _coverPool, address _cvc) private {
    address[] memory cvcCopy = cvcMap[_coverPool];
    uint256 len = cvcCopy.length;
    if (len < 1) return; // nothing to remove, no need to revert
    for (uint256 i = 0; i < len; i++) {
      if (_cvc == cvcCopy[i]) {
        cvcMap[_coverPool][i] = cvcCopy[len - 1];
        cvcMap[_coverPool].pop();
        break;
      }
    }
  }

  // Updates fee for coverPool `_coverPool` by multiplying current fee by `feeMultiplier`, capped at `forceClaimFee`
  function _updateCoverPoolClaimFee(address _coverPool) internal {
    uint256 newFee = getCoverPoolClaimFee(_coverPool) * feeMultiplier;
    if (newFee <= forceClaimFee) {
      coverPoolClaimFee[_coverPool] = newFee;
    }
  }

  // Resets fee for coverPool `_coverPool` to `baseClaimFee`
  function _resetCoverPoolClaimFee(address _coverPool) internal {
    coverPoolClaimFee[_coverPool] = baseClaimFee;
  }
}