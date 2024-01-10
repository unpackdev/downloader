// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

interface IEchoSale {
  event Remaining(uint256 remaining);

  function setEcho(address echo) external;
  function setMintMaximum(uint256 max) external;
  
  function earlyMint(uint256 quantity) payable external;
  function addEarlyAccess(address address1, address address2, address address3, address address4, address address5) external;
  function removeEarlyAccess(address address1, address address2, address address3, address address4, address address5) external;
  function enableEarlyMint(uint start, uint end, uint256 price) external;

  function mint(uint256 quantity) payable external;
  function enableMint(uint start, uint end, uint256 price) external;

  function mintFor(address to, uint256 quantity) external;

  function hasEarlyAccess() view external returns (bool hasAccess);
  function getEarlyAccessInformation() view external returns (bool hasAccess, uint start, uint end, uint256 price);
  function getMintInformation(uint time) view external returns (uint start, uint end, uint256 price, uint256 remaining);

  function Echo() view external returns (address);
  function MintMaximum() view external returns (uint256);
}