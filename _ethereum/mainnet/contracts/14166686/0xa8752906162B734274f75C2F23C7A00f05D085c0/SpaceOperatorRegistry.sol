// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./AccessControlUpgradeable.sol";
import "./ISpaceOperatorRegistry.sol";

contract SpaceOperatorRegistry is
    ISpaceOperatorRegistry,
    AccessControlUpgradeable
{
    bytes32 public constant SPACE_OPERATOR_REGISTER_ROLE =
        keccak256("SPACE_OPERATOR_REGISTER_ROLE");

    mapping(address => uint8) public operatorToComission;
    mapping(address => bool) public isApprovedOperator;

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SPACE_OPERATOR_REGISTER_ROLE, msg.sender);
    }

    function getPlatformCommission(address _operator)
        external
        view
        override
        returns (uint8)
    {
        return operatorToComission[_operator];
    }

    function setPlatformCommission(address _operator, uint8 _commission)
        external
        override
    {
        require(hasRole(SPACE_OPERATOR_REGISTER_ROLE, msg.sender));
        operatorToComission[_operator] = _commission;
    }

    function isApprovedSpaceOperator(address _operator)
        external
        view
        override
        returns (bool)
    {
        return isApprovedOperator[_operator];
    }

    function setSpaceOperatorApproved(address _operator, bool _approved)
        external
        override
    {
        require(hasRole(SPACE_OPERATOR_REGISTER_ROLE, msg.sender));
        isApprovedOperator[_operator] = _approved;
    }
}
