// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./Ownable.sol";

contract OperatorLocker is AccessControl, Ownable {
    bytes32 public constant ADMIN = "ADMIN";

    mapping(uint => mapping(address => bool)) private _allowlisted;

    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    function operatorIsLocked(uint256 _level, address _operator) external view returns (bool) {
        if (_level == 0) return false;
        return !_allowlisted[_level][_operator];
    }

    function setAllowlisted(uint256 _level, address[] calldata  _operators, bool _value) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _operators.length; i++) {
            _allowlisted[_level][_operators[i]] = _value;
        }
    }
}