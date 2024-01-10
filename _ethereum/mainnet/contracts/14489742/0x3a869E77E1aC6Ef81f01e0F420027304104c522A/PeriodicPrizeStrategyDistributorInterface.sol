pragma solidity 0.6.12;

import "./PeriodicPrizeStrategy.sol";

/* solium-disable security/no-block-members */
interface PeriodicPrizeStrategyDistributorInterface {
  function distribute(uint256 randomNumber) external;
}