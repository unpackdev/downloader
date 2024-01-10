// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IIdolMain {
  function mint(address _mintAddress, uint _godId, bool _lock) external;
  function depositSteth(uint _stethAmt) external;
  function setBaseURI(string memory uri) external;
  function setVirtueTokenAddr(address _idolAddr) external;
  function setIdolMarketplaceAddr(address _marketplaceAddr) external;
  function balanceOf(address _owner) external view returns (uint256);
}
