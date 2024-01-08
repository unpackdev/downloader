// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./AaveV2Interfaces.sol";


library ReserveConfigurationLib {
  uint256 internal constant RESERVE_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK                  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;

  /**
   * @dev Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(ILendingPool.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  function isFrozen(ILendingPool.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~FROZEN_MASK) != 0;
  }
}