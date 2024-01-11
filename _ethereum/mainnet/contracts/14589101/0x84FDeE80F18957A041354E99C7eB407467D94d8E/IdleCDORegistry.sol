// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Ownable.sol";

interface IIdleCDO {
  function token() external view returns (address);
}

error Invalid();

contract IdleCDORegistry is Ownable {
  mapping(address => bool) public isValidCdo;

  constructor(address[] memory _cdos) {
    uint256 _cdoLen = _cdos.length;
    for (uint256 i = 0; i < _cdoLen;) {
      isValidCdo[_cdos[i]] = true;
      unchecked {
        ++i;
      }
    }
  }

  function toggleCDO(address _cdo, bool _valid) external onlyOwner {
    if (_cdo == address(0)) {
      revert Invalid();
    }
    isValidCdo[_cdo] = _valid;
  }
}
