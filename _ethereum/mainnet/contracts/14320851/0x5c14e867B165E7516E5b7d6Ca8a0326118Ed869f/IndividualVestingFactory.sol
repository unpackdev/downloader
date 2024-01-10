//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./Clones.sol";
import "./IIndividualVesting.sol";
import "./IndividualVesting.sol";

contract IndividualVestingFactory {
  address public immutable implementation;

  event IndividualVestingCreated(address instanceAddress, address _receiverAddress, uint256 _grantedAmount, uint256 _withdrawnAmount);

  constructor() {
    implementation = address(new IndividualVesting());
  }

  function createVesting(
    address _receiverAddress,
    uint256 _grantedAmount,
    uint256 _withdrawnAmount
  ) public {
    address instanceAddress = Clones.clone(implementation);
    IIndividualVesting(instanceAddress).initialize(_receiverAddress, _grantedAmount, _withdrawnAmount);
    emit IndividualVestingCreated(instanceAddress, _receiverAddress, _grantedAmount, _withdrawnAmount);
  }
}
