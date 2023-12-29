pragma solidity >=0.5.0;

interface IFlashLoanReceiver {
  function executeOperation(
    address asset,
    uint amount,
    uint premium,
    address initiator,
    bytes calldata params
  ) external returns (bool);
}
