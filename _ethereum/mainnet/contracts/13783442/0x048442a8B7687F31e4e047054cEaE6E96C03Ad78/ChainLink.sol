// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
interface ChainLink {
  function getRate(address coincontract) external view returns (uint16,uint16,uint16,uint16,uint16);
  function checkPrice(address coincontract,uint256 price) external view returns (bool);
  function getIsOpen()external view returns (bool);
}