// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;

abstract contract IValidatorsRegister {
    function _getValidator(address account) internal virtual returns (uint256);

    function _addValidator(address account, uint16 id) internal virtual returns (uint256);

    function _removeValidator(address account) internal virtual returns (uint256);

    function _getLastValidatorId() internal view virtual returns (uint64);

    function totalValidators() public view virtual returns (uint32);
}