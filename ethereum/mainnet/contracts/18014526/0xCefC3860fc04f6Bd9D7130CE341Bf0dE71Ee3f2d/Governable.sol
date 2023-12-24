// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGovernable.sol";
import "./OwnableV2.sol";

/**
 * @title Governable
 * 
 * parent for governable contracts
 */
abstract contract Governable is IGovernable, OwnableV2 {
  constructor(address owner_, address governor_) OwnableV2(owner_) {
    _governor_ = governor_;
    emit GovernorshipTransferred(address(0), _governor());
  }

  address internal _governor_;

  function _governor() internal view returns (address) {
    return _governor_;
  }

  function governor() external view override returns (address) {
    return _governor();
  }

  modifier onlyGovernor() {
    require(_governor() == _msgSender(), "Only the governor can execute this function");
    _;
  }

  // not currently used - but here it is in case we want this
  // modifier onlyOwnerOrGovernor() {
  //   require(_owner() == _msgSender() || _governor() == _msgSender(), "Only the owner or governor can execute this function");
  //   _;
  // }

  function _transferGovernorship(address newGovernor) internal virtual {
    // keep track of old owner for event
    address oldGovernor = _governor();

    // set the new owner
    _governor_ = newGovernor;

    // emit event about ownership change
    emit GovernorshipTransferred(oldGovernor, _governor());
  }

  function transferGovernorship(address newGovernor) external override onlyOwner {
    _transferGovernorship(newGovernor);
  }
}
