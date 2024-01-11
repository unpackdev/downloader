pragma solidity ^0.8.0;

interface IRootManger {
       function safeDeposit(address account,uint256 value) external returns (uint256);
       function safeWithdraw(address account,uint256 to_burn) external ;
       function balanceOfTorn(address account) external view returns (uint256);
       function addIncome(uint256 amount)  external ;
       function valueForTorn(uint256 value_token)  external view returns (uint256);
       function operator() external view returns(address);
       function depositContract() external view returns(address);
       function inComeContract() external view returns(address);

       function  exitQueueContract() external view returns (address);
       function totalTorn() external view returns (uint256);
       function removeRelayer(uint256 index)  external  ;
       function addRelayer(address __relayer,uint256 index)  external  ;
       function _relayers(uint256 index) external view returns (address);
       function totalRelayerTorn() external view returns (uint256 ret);
}
