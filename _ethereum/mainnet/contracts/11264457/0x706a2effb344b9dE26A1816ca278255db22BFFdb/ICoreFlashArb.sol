pragma solidity ^0.6.12;
interface ICoreFlashArb {
  function executeStrategy ( uint256 strategyPID ) external;
  function numberOfStrategies (  ) external view returns ( uint256 );
  function strategyProfitInReturnToken ( uint256 strategyID ) external view returns ( uint256 profit );
}
