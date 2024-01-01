// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IAccessControl.sol";
import "./Context.sol";
import "./CflatsDatabaseErrors.sol";
import "./ICflatsDappRequirements.sol";


abstract contract CflatsDappRequirements is ICflatsDappRequirements, Context
{
    bytes32 private constant _DEFAULT_ADMIN_ROLE = 0x00;
    ICflatsDatabase private immutable _DATABASE;
    constructor(ICflatsDatabase database)
    {
        _DATABASE = database;
    }


    function getDatabase() public view returns (ICflatsDatabase)
    {
        return _DATABASE;
    }



    modifier onlyNotBlacklisted()
    {
        _requireNotBlacklisted(_msgSender());
        _;
    }

    modifier onlyAdmin()
    {
        _requireNotBlacklisted(_msgSender());
        _;
    }

    modifier onlyOperator()
    {
        _requireOperator(_msgSender());
        _;
    }

    modifier onlyDeveloper()
    {
        _requireDeveloper(_msgSender());
        _;
    }



    function _requireAdmin(address user) private view
    {
        _requireNotBlacklisted(user);
        
        if(IAccessControl(address(_DATABASE)).hasRole(_DEFAULT_ADMIN_ROLE, user) != true)
        {
            revert OnlyOperatorCanCallThisFunction();
        }
    }

    function _requireOperator(address user) private view
    {
        _requireNotBlacklisted(user);
        
        if(IAccessControl(address(_DATABASE)).hasRole(_DATABASE.OPERATOR_ROLE(), user) != true)
        {
            revert OnlyOperatorCanCallThisFunction();
        }
    }

    function _requireDeveloper(address user) private view
    {
        _requireNotBlacklisted(user);
        
        if(IAccessControl(address(_DATABASE)).hasRole(_DATABASE.DEVELOPER_ROLE(), user) != true)
        {
            revert OnlyOperatorCanCallThisFunction();
        }
    }

    function _requireNotBlacklisted(address user) private view 
    {
        if(_DATABASE.isBlacklisted(user))
        {
            revert BlacklistedError();
        }
    }
}
