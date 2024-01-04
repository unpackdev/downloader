// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ServiceInterface {
  function isEntityActive(address entity) external view returns (bool);

  function getTraunch(address entity) external view returns (uint256);
}
