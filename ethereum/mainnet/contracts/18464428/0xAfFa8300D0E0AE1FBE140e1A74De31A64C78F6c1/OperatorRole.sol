// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.9;
/*
 *@#+:-*==   .:. :     =#*=.  ..    :=**-    :+%@@@@@#*+-..........        .-.-@@
 *%%*.. +*:    =%.--     :+***+=++**=.    .+%@@@@@*-            . . .     .  -+= 
 *         -==+++. :#:        ..       .=#@@@@@*-   .:=*#%@@@@%#*=.  ...:::::    
 *     .:-======+=--%@*.             .*@@@@@@+   .=#@@@@@@##*#%@@@@@*-           
 *-:::-===-::------+#@@@*.         :*@@@@@@=   :*@@@%*==------=--+@@@@@#=:    .-=
 *=++==:::      .:=+=:.-=. .-**+++#**#@@@+   -#@@%=-::==       :*+--*@@@@@@@@@@@@
 *.....-=*+***+-.   .+#*-    +@@@@@@@@@+.  -%@@%-::. .-     .::-@@@%- -#@@@@@@@@@
 *   :*=@@@@@@@@@@#=.  -*@%#%@@@@@@@@*.  :#@@%-::    :=    =*%@@@@@@@%++*+*%@@@@@
 * .+*%@#+-:-=+*##*#@#=.  -*%@@@@@#=.  -#@@%-::       -:       :+@@@@@@@@*:  ..  
 *@@@%=         .-. :*@@#=.   ...   .=%@@#-:-      :-=++#####+=:  -#@@@@@@@@%*+++
 *@*:       :-=+::..   -#@@%+==--=+#@@%=.:+*=  :=*%@@@@%@@@@@@@@@*- .+%@@@@ SMG @
 *.     .+%@@=%%%##=....  :+*%%@@%#+-. =%@@@@@@%@@@@@@@@@@@%%%%@@@@@#=:-+%@@@@@@@
 */
import "./AccessControlEnumerable.sol";

/**
 * @title OperatorRole 
 * @notice Copyright (c) 2023 Special Mechanisms Group
 *
 * @author SMG <dev@mechanism.org>
 *
 * @dev The OperatorRole contract defines a role called OPERATOR_ROLE which can 
 *      be assigned to certain addresses, and which can be used to control 
 *      access to certain functions on the smart contract. In addition, this
 *      contract sets up the DEFAULT_ADMIN_ROLE.
 */
abstract contract OperatorRole is AccessControlEnumerable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event AddedOperator(address indexed _address);
    event RemovedOperator(address indexed _address);

    /**
     * @notice Constructor
     *
     * @dev The deployer will be set as the first address with the roles
     *      DEFAULT_ADMIN_ROLE and OPERATOR_ROLE. DEFAULT_ADMIN_ROLE is set 
     *      as the administrator of OPERATOR_ROLE, which means that only a 
     *      caller with the DEFAULT_ADMIN_ROLE can call the `grantRole` or 
     *      `renounceRole` functions for OPERATOR_ROLE. 
     */
    constructor() 
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());
    }

    /**
     * @notice Allows only the Operator role to call certain functions.
     */
    modifier onlyOperator() 
    {
        require(isOperator(_msgSender()), "OperatorRole: caller does not have the Operator role.");
        _;
    }

    /**
     * @notice Checks whether an address has been granted OPERATOR_ROLE.
     * 
     * @param _address Address to check.
     * @return bool 'true' if the address has the role, otherwise 'false'. 
     */
    function isOperator(
        address _address
    ) 
        public 
        view 
        returns (bool) 
    {
        return hasRole(OPERATOR_ROLE, _address);
    }

    /**
     * @notice Give an address OPERATOR_ROLE.
     *
     * @dev Caller must have DEFAULT_ADMIN_ROLE.
     * 
     * @param _address Address to be granted OPERATOR_ROLE.
     */
    function addOperator(
        address _address
    ) 
        public 
    {
        _addOperator(_address);
    }

    /**
     * @notice Remove OPERATOR_ROLE from msg.sender.
     *
     * @dev Caller must have OPERATOR_ROLE.
     */
    function renounceOperator() 
        public 
        virtual 
    {
        _removeOperator(msg.sender);
    }

    /**
     * @notice Add OPERATOR_ROLE to an address.
     *
     * @dev Caller must have DEFAULT_ADMIN_ROLE.
     * 
     * @param _address Address to have OPERATOR_ROLE granted.
     */
    function _addOperator(
        address _address
    ) 
        internal 
    {
        grantRole(OPERATOR_ROLE, _address);
        emit AddedOperator(_address);
    }

    /**
     * @notice Remove OPERATOR_ROLE from an address.
     *
     * @dev Caller must have DEFAULT_ADMIN_ROLE.
     * 
     * @param _address Address to have OPERATOR_ROLE renounced.
     */
    function _removeOperator(
        address _address
    ) 
        internal 
    {
        renounceRole(OPERATOR_ROLE, _address);
        emit RemovedOperator(_address);
    }

    /**
     * @dev Overload {AccessControlEnumerable-_revokeRole} to ensure at least one operator/admin remains
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        uint256 roleMemberCount = getRoleMemberCount(role);
        require (roleMemberCount > 0, "OperatorRole: contract must have at least one operator");
    }

    /**
     * @dev Overload {AccessControl-_renounceRole} to ensure at least one operator/admin remains
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }
}
