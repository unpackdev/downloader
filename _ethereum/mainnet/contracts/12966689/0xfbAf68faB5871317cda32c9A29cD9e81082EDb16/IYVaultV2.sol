pragma solidity ^0.8.5;

interface IYVaultV2 {
  function totalSupply() external view returns (uint256);

  function pricePerShare() external view returns (uint256);
}
