// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BaseMinter.sol";

contract BlockMintAuthorizer is BaseMinter {
  address private immutable _minterAddress;
  uint256 private immutable _price;

  constructor(
    address entryPoint,
    string memory mintName,
    uint256 totalMintLimit,
    address minterAddress,
    uint256 price,
    uint256 startTime,
    uint256 endTime
  ) BaseMinter(entryPoint, mintName, totalMintLimit, startTime, endTime) {
    _minterAddress = minterAddress;
    _price = price;
  }

  function getProofRequired() external pure override returns (bool) {
    return false;
  }

  function getUserMintPrice(address, bytes32[] memory) public view override returns (uint256) {
    return _price;
  }

  function getUserMintLimit(address user, bytes32[] memory) external view override returns (uint256) {
    if (user == _minterAddress) {
      return _totalMintLimit;
    } else {
      return 0;
    }
  }

  function getUserMintCount(address user) external view override returns (uint256) {
    if (user == _minterAddress) {
      return _totalMintCount;
    } else {
      return 0;
    }
  }

  function authorizeMint(
    address sender,
    uint256 value,
    uint256 number,
    bytes32[] memory
  ) external override {
    _authorizeMint(number);

    require(sender == _minterAddress, "Unauthorized minter");
    require(value >= _price * number, "Insufficient payment");
  }
}
