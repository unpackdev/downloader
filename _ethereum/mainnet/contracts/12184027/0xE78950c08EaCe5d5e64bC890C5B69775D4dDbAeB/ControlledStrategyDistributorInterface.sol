pragma solidity >=0.6.0 <0.7.0;

import "./ControlledStrategy.sol";

/* solium-disable security/no-block-members */
interface ControlledStrategyDistributorInterface {
  function distribute() external;
}