// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.7.0;

import "./OwnableUpgradeable.sol";

import "./ReserveInterface.sol";
import "./BarnPrizePoolInterface.sol";

/// @title Interface that allows a user to draw an address using an index
contract Reserve is OwnableUpgradeable, ReserveInterface {

  event ReserveRateMantissaSet(uint256 rateMantissa);

  uint256 public rateMantissa;

  constructor () public {
    __Ownable_init();
  }

  function setRateMantissa(
    uint256 _rateMantissa
  )
    external
    onlyOwner
  {
    rateMantissa = _rateMantissa;

    emit ReserveRateMantissaSet(rateMantissa);
  }

  function withdrawSplitReserve(address prizePool) external returns (uint256) {
    return BarnPrizePoolInterface(prizePool).withdrawSplitReserve();
  }

  function reserveRateMantissa(address) external view override returns (uint256) {
    return rateMantissa;
  }
}
