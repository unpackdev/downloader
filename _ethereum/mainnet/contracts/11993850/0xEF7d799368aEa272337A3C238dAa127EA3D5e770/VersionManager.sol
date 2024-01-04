// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./VersionBeacon.sol";


contract VersionManager
{
  address private constant _versionBeacon = address(0xfc90c4ae4343f958215b82ff4575b714294Cdd75);


  function getVersionBeacon() public pure returns (address versionBeacon)
  {
    return _versionBeacon;
  }


  function _oracle() internal view returns (address oracle)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("Oracle"));
  }

  function _tokenMgr() internal view returns (address tokenMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("TokenManager"));
  }

  function _discountMgr() internal view returns (address discountMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("DiscountManager"));
  }

  function _feeBurnMgr() internal view returns (address feeBurnMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("FeeBurnManager"));
  }

  function _rewardMgr() internal view returns (address rewardMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("RewardManager"));
  }

  function _collateralMgr() internal view returns (address collateralMgr)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("CollateralManager"));
  }

  function _loanFactory() internal view returns (address loanFactory)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("LoanFactory"));
  }

  function _offerImplementation() internal view returns (address offerImplementation)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("Offer"));
  }

  function _requestImplementation() internal view returns (address requestImplementation)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("Request"));
  }

  function _loanImplementation() internal view returns (address loanImplementation)
  {
    return IVersionBeacon(_versionBeacon).getLatestImplementation(keccak256("Loan"));
  }
}
