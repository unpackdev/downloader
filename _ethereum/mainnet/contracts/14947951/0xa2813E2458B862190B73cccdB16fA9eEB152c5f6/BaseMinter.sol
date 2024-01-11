// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC165Storage.sol";

import "./IRebelsMintAuthorizer.sol";
import "./IRebelsMintInfo.sol";

abstract contract BaseMinter is IRebelsMintAuthorizer, IRebelsMintInfo, ERC165Storage {
  address private immutable _entryPoint;
  string private _mintName;

  uint256 internal immutable _totalMintLimit;
  uint256 internal _totalMintCount;

  uint256 internal immutable _startTime;
  uint256 internal immutable _endTime;

  constructor(
    address entryPoint,
    string memory mintName,
    uint256 totalMintLimit,
    uint256 startTime,
    uint256 endTime
  ) {
    require(startTime < endTime);

    _entryPoint = entryPoint;
    _mintName = mintName;
    _totalMintLimit = totalMintLimit;
    _startTime = startTime;
    _endTime = endTime;

    _registerInterface(type(IRebelsMintAuthorizer).interfaceId);
    _registerInterface(type(IRebelsMintInfo).interfaceId);
  }

  function getMintName() external view override returns (string memory) {
    return _mintName;
  }

  function getMintActive() public view override returns (bool) {
    return _startTime <= block.timestamp && block.timestamp < _endTime;
  }

  function getMintStartTime() external view override returns (uint256) {
    return _startTime;
  }

  function getMintEndTime() external view override returns (uint256) {
    return _endTime;
  }

  function getTotalMintLimit() external view override returns (uint256) {
    return _totalMintLimit;
  }

  function getTotalMintCount() external view override returns (uint256) {
    return _totalMintCount;
  }

  function _authorizeMint(
    uint256 number
  ) internal {
    require(msg.sender == _entryPoint);

    require(getMintActive(), "Mint is not active");

    uint256 newTotalMintCount = _totalMintCount + number;
    require(newTotalMintCount <= _totalMintLimit,
            "Trying to mint more than total allowed");
    _totalMintCount = newTotalMintCount;
  }
}
