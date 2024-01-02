// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;

import "./IValidatorsRegister.sol";
import "./BitMaps.sol";
import "./IValidatorsRegisterStorage.sol";

/// The specified validator id is too small. It must be grater than zero.
error ValidatorIdTooSmall();
/// The validator with the specified account already exists.
/// @param account The validator address.
error ValidatorAlreadyExists(address account);
/// The specified validator id is already occupied.
/// @param id The validator id.
error ValidatorIdOccupied(uint16 id);
/// The specified validator account does not exists.
/// @param account The validator address.
error ValidatorNotExists(address account);

abstract contract ValidatorsRegister is IValidatorsRegisterStorage, IValidatorsRegister {
    using BitMaps for BitMaps.BitMap;

    function _getValidator(address account) internal override view returns (uint256) {
        return _readValidator(account);
    }

    function _addValidator(address account, uint16 id) internal override returns (uint256) {
        if (id == 0) {
            revert ValidatorIdTooSmall();
        }
        if (_readValidator(account) != 0) {
            revert ValidatorAlreadyExists(account);
        }
        if (_readValidatorIds().get(id)) {
            revert ValidatorIdOccupied(id);
        }
        ValidatorsInfo memory info = _readValidatorsInfo();
        info.totalValidators ++;
        if (id > info.lastValidatorId) {
            info.lastValidatorId = id;
        }
        _writeValidatorsInfo(info);
        _writeValidator(account, id);
        _readValidatorIds().setTo(id, true);
        return info.lastValidatorId;
    }

    function _removeValidator(address account) internal override returns (uint256) {
        uint256 id = _readValidator(account);
        if (id == 0) {
            revert ValidatorNotExists(account);
        }
        _deleteValidator(account);
        _readValidatorsInfo().totalValidators --;
        _readValidatorIds().setTo(id, false);
        return id;
    }

    function _getLastValidatorId() internal view override returns (uint64) {
        return _readValidatorsInfo().lastValidatorId;
    }

    function totalValidators() public view override returns (uint32) {
        return _readValidatorsInfo().totalValidators;
    }
}