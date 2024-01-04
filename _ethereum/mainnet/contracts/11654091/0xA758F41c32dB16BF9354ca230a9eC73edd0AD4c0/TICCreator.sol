// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IDerivative.sol";
import "./IFinder.sol";
import "./ITIC.sol";
import "./Lockable.sol";
import "./TIC.sol";

contract TICCreator is Lockable {
  function createTIC(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    SynthereumTICInterface.Roles memory roles,
    uint256 startingCollateralization,
    SynthereumTICInterface.Fee memory fee
  ) public virtual nonReentrant returns (SynthereumTIC poolDeployed) {
    poolDeployed = new SynthereumTIC(
      derivative,
      finder,
      version,
      roles,
      startingCollateralization,
      fee
    );
  }
}
