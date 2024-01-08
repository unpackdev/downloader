// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./OwnableUpgradeable.sol";

import "./ReserveInterface.sol";
import "./PrizePoolInterface.sol";

contract Reserve is OwnableUpgradeable, ReserveInterface {

  event ReserveRateMantissaSet(uint256 rateMantissa);

  uint256 public rateMantissa;

  constructor (uint256 _rateMantissa) public {
    rateMantissa = _rateMantissa;
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

  function withdrawReserve(address prizePool, address to) external onlyOwner returns (uint256) {
    return PrizePoolInterface(prizePool).withdrawReserve(to);
  }

  function reserveRateMantissa() external view override returns (uint256) {
    return rateMantissa;
  }
}
