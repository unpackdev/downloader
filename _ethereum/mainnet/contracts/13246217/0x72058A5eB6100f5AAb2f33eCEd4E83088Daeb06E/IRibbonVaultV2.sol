pragma solidity ^0.8.5;

// Ribbon vault
interface IRibbonVaultV2 {
  function totalSupply() external view returns (uint256);

  function pricePerShare() external view returns (uint256);
}
