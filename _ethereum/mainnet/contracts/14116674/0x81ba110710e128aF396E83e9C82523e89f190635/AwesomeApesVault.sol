// SPDX-License-Identifier: GPL-3.0

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract AwesomeApesVault is ReentrancyGuard, Ownable {
  // Storage of receiving addresses
  address[] public vaults;

  // Storage of numerators of each vault
  mapping(address => uint) public numerators;
  // Storage of denominators of each vault
  mapping(address => uint) public denominators;

  // Initializes while setting `vault`
  constructor(address[] memory _vaults, uint[] memory _numerators, uint[] memory _denominators) {
    for (uint i; i < _vaults.length; i++){
      // Store address
      vaults.push(_vaults[i]);

      // Set numerator
      numerators[_vaults[i]] = _numerators[i];

      // Set denominator
      denominators[_vaults[i]] = _denominators[i];
    }
  }

  // Receiving ETH function
  receive() external payable {}

  // Fallback receiving ETH function
  fallback() external payable {}

  // Updates an address within `vaults`
  function setVault(address _vault, uint _index) external onlyOwner {
    require(_index < vaults.length, 'Invalid Index Value.');
    vaults[_index] = _vault;
  }

  // Sets the numerator of the rate of vault to receive
  function setNumerator(address _vault, uint _numerator) external onlyOwner {
    numerators[_vault] = _numerator;
  }

  // Sets the denominator of the rate of vault to receive
  function setDenominator(address _vault, uint _denominator) external onlyOwner {
    denominators[_vault] = _denominator;
  }

  // Returns the sum of shares of each vault
  function validate() external view onlyOwner returns (uint) {
     return (
       (1 ether * numerators[vaults[0]] / denominators[vaults[0]]) +
       (1 ether * numerators[vaults[1]] / denominators[vaults[1]]) +
       (1 ether * numerators[vaults[2]] / denominators[vaults[2]]) +
       (1 ether * numerators[vaults[3]] / denominators[vaults[3]]) +
       (1 ether * numerators[vaults[4]] / denominators[vaults[4]])
     ) / 1 ether;
  }

  // Sends balance of contract to addresses stored in `vaults`
  function withdraw() external nonReentrant {
    uint payment0 = address(this).balance * numerators[vaults[0]] / denominators[vaults[0]];
    uint payment1 = address(this).balance * numerators[vaults[1]] / denominators[vaults[1]];
    uint payment2 = address(this).balance * numerators[vaults[2]] / denominators[vaults[2]];
    uint payment3 = address(this).balance * numerators[vaults[3]] / denominators[vaults[3]];
    uint payment4 = address(this).balance * numerators[vaults[4]] / denominators[vaults[4]];

    require(payable(vaults[0]).send(payment0));
    require(payable(vaults[1]).send(payment1));
    require(payable(vaults[2]).send(payment2));
    require(payable(vaults[3]).send(payment3));
    require(payable(vaults[4]).send(payment4));
  }
}
