// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title IDebtToken
 * @author BendDao; Forked and edited by Unlockd
 * @notice Defines the basic interface for a debt token.
 **/
interface ICryptoPunksMarket {
  function punkIndexToAddress(uint256 index) external view returns (address);
}
