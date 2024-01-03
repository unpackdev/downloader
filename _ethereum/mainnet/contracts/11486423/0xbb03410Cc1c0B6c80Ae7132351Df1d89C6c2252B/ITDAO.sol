// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface ITDAO {
  function startLiquidityEventTime() external view returns (uint256);

  function maxSupply() external view returns (uint256);

  function governance() external view returns (address);

  function feeController() external view returns (address);

  function feeSplitter() external view returns (address);

  function lockedLiquidityEvent() external view returns (address);

  function claimERC20(address, address) external;

  function setTreasuryVault(address) external;

  function setTrigFee(uint256) external;

  function setFee(uint256) external;

  function editNoFeeList(address, bool) external;

  function editBlackList(address, bool) external;

  function setDependencies(
    address,
    address,
    address
  ) external;

  function delegates(address) external view returns (address);

  function delegate(address) external;

  function getCurrentVotes(address account) external view returns (uint256);

  function getPriorVotes(address, uint256) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}
