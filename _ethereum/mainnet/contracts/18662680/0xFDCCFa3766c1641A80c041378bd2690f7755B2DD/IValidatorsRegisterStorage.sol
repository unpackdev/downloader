// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BitMaps.sol";

abstract contract IValidatorsRegisterStorage {
    struct ValidatorsInfo {
        // supporting more than 1000 validators might lead to significant gas usage
        // this issue will be solved when validators migrate to TSS
        uint16 lastValidatorId;
        uint16 totalValidators;
        uint224 reserved;
    }

    function _readValidator(address account) internal view virtual returns (uint256);
    function _writeValidator(address account, uint256 id) internal virtual;
    function _deleteValidator(address account) internal virtual;
    function _readValidatorIds() internal view virtual returns (BitMaps.BitMap storage);
    function _readValidatorsInfo() internal view virtual returns (ValidatorsInfo storage);
    function _writeValidatorsInfo(ValidatorsInfo memory info) internal virtual;
}
