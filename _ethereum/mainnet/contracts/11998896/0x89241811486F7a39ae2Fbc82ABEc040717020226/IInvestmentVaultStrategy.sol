pragma solidity 0.5.16;

interface IInvestmentVaultStrategy {

  function rewardTokensLength() external view returns (uint256);
  function getAllRewards() external ;
  function hodlApproved() external view returns(bool);
  function rewardTokens(uint256 i) external view returns(address);

}

