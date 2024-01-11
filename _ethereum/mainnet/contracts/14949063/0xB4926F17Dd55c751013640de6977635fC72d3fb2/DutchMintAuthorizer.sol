// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BaseMinter.sol";

contract DutchMintAuthorizer is BaseMinter {
  uint256 private immutable _userMintLimit;
  mapping(address => uint256) private _userMintCount;

  uint256 private immutable _startPrice;
  uint256 private immutable _endPrice;

  constructor(
    address entryPoint,
    string memory mintName,
    uint256 totalMintLimit,
    uint256 userMintLimit,
    uint256 startPrice,
    uint256 endPrice,
    uint256 startTime,
    uint256 endTime
  ) BaseMinter(entryPoint, mintName, totalMintLimit, startTime, endTime) {
    require(startPrice > endPrice);

    _userMintLimit = userMintLimit;
    _startPrice = startPrice;
    _endPrice = endPrice;
  }

  function getProofRequired() external pure override returns (bool) {
    return false;
  }

  function _getUserMintPrice() internal view returns (uint256) {
    if (block.timestamp > _endTime) {
      return _endPrice;
    } else if (block.timestamp >= _startTime) {
      uint256 duration = _endTime - _startTime;
      uint256 discount = _startPrice - _endPrice;
      uint256 elapsed = block.timestamp - _startTime;
      return _startPrice - ((discount * elapsed) / duration);
    } else {
      return _startPrice;
    }
  }

  function getUserMintPrice(address, bytes32[] memory) public view override returns (uint256) {
    return _getUserMintPrice();
  }

  function getUserMintLimit(address, bytes32[] memory) external view override returns (uint256) {
    return _userMintLimit;
  }

  function getUserMintCount(address user) external view override returns (uint256) {
    return _userMintCount[user];
  }

  function authorizeMint(
    address sender,
    uint256 value,
    uint256 number,
    bytes32[] memory
  ) external override {
    _authorizeMint(number);

    uint256 newMintCount = _userMintCount[sender] + number;
    require(newMintCount <= _userMintLimit, "Trying to mint more than allowed");
    _userMintCount[sender] = newMintCount;

    require(value >= _getUserMintPrice() * number, "Insufficient payment");
  }
}
