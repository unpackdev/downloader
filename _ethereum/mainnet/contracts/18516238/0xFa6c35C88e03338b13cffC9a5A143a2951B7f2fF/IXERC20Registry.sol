// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IXERC20Registry {
  // ========== Events ===========
  event XERC20Registered(address indexed XERC20, address indexed ERC20);

  event XERC20Deregistered(address indexed XERC20, address indexed ERC20);

  // ========== Custom Errors ===========
  error AlreadyRegistered(address XERC20);

  error XERC20NotRegistered(address XERC20);

  error InvalidXERC20Address(address XERC20);

  // ========== Function Signatures ===========
  function initialize() external;

  function registerXERC20(address _XERC20, address _ERC20) external;

  function deregisterXERC20(address _xERC20) external;

  function getERC20(address _XERC20) external view returns (address);

  function getXERC20(address _ERC20) external view returns (address);

  function getLockbox(address _XERC20) external view returns (address);

  function isXERC20(address _XERC20) external view returns (bool);
}
