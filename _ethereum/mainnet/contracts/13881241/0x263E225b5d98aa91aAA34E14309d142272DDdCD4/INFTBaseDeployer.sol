// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INFTBaseDeployer {
  function deployNFTBase(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _timelock,
    address _erc721
  ) external returns (address);
}
