// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;


interface ITreasury {
  function getBondingCalculator() external returns (address);
  // function payDebt( address depositor_ ) external returns ( bool );
  function getTimelockEndBlock() external returns (uint);
  function getManagedToken() external returns (address);
  // function getDebtAmountDue() external returns ( uint );
  // function incurDebt( uint principieTokenAmountDeposited_, uint bondScalingValue_ ) external returns ( bool );
}
