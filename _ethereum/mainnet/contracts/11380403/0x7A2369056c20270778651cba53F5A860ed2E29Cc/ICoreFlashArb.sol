// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ICoreFlashArb {
      struct Strategy {
        string strategyName;
        bool[] token0Out; // An array saying if token 0 should be out in this step
        address[] pairs; // Array of pair addresses
        uint256[] feeOnTransfers; //Array of fee on transfers 1% = 10
        bool cBTCSupport; // Should the algorithm check for cBTC and wrap/unwrap it
                        // Note not checking saves gas
        bool feeOff; // Allows for adding CORE strategies - where there is no fee on the executor
    }
  function executeStrategy ( uint256 strategyPID ) external;
  function numberOfStrategies (  ) external view returns ( uint256 );
  function strategyProfitInReturnToken ( uint256 strategyID ) external view returns ( uint256 profit );
  function strategyInfo(uint256 strategyPID) external view returns (Strategy memory);
  function mostProfitableStrategyInETH (  ) external view returns ( uint256 profit, uint256 strategyID );
}
