// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./AccessControlUpgradeable.sol";

abstract contract OwnerOperatorControl is AccessControlUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');

    function __OwnerOperatorControl_init() internal {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Role: not Admin');
        _;
    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), 'Role: not Operator');
        _;
    }

    function isOperator(address _address) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, _address);
    }
}
