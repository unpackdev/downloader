// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface AutoRefactorCoinageI {

  struct Balance {
    uint256 balance;
    uint256 refactoredCount;
    uint256 remain;
  }

  function factor() external view returns (uint256);
  function setFactor(uint256 factor_) external returns (bool);
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function mint(address account, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function addMinter(address account) external;
  function renounceMinter() external;
  function transferOwnership(address newOwner) external;

  function balances(address account) external view returns (Balance memory);
  function _totalSupply() external view returns (Balance memory);
  function _factor() external view returns (uint256);
  function refactorCount() external view returns (uint256);
}
