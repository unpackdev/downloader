// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

error AccessControlIsInitialized();
error AccessDenied(address executor, uint256 deniedForRole);

library AccessControlLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.accesscontrol.storage");
    uint256 constant FULL_PRIVILEGES_MASK = type(uint256).max;
    uint256 constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint32 constant ROLE_CREATE_MANAGER = 0x0001_0000;
    uint32 constant ROLE_DELETE_MANAGER = 0x0002_0000;
    uint32 constant ROLE_EDIT_MANAGER = 0x0004_0000;
    uint32 constant ROLE_CONFIG_MANAGER = 0x0008_0000;
    uint32 constant ROLE_INVEST_MANAGER = 0x0010_0000;
    uint32 constant ROLE_WITHDRAW_MANAGER = 0x0020_0000;
    uint32 constant ROLE_DISTRIBUTE_MANAGER = 0x0040_0000;
    uint32 constant ROLE_FEE_MANAGER = 0x0080_0000;

    struct AccessControlState {
        mapping(address => uint256) userRoles;
        bool isInitialized;
    }

    event RoleUpdated(address indexed by, address indexed to, uint256 requested, uint256 actual);

    function diamondStorage() internal pure returns (AccessControlState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

	function hasRole(uint256 _actual, uint256 _required) internal pure returns(bool) {
		return _actual & _required == _required;
	}
    
    function features() internal view returns(uint256) {
		AccessControlState storage accessControlState = diamondStorage();
        return accessControlState.userRoles[address(this)];
	}

    function isFeatureEnabled(uint256 _required) internal view returns(bool) {
		return hasRole(features(), _required);
	}

    function isOperatorInRole(address _operator, uint256 _required) internal view returns(bool) {
		AccessControlState storage accessControlState = diamondStorage();
        return hasRole(accessControlState.userRoles[_operator], _required);
	}

	function isSenderInRole(uint256 _required) internal view returns(bool) {
		return isOperatorInRole(msg.sender, _required);
	}

    function evaluateBy(address _operator, uint256 _target, uint256 _desired) internal view returns(uint256) {
		AccessControlState storage accessControlState = diamondStorage();
		uint256 p = accessControlState.userRoles[_operator];
        _target |= p & _desired;
		_target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ _desired));
		return _target;
	}

    function initializeAccessControl() internal {
        LibDiamond.enforceIsContractOwner();
        AccessControlState storage accessControlState = diamondStorage();
        if(accessControlState.isInitialized) {
            revert AccessControlIsInitialized();
        }
        accessControlState.userRoles[LibDiamond.contractOwner()] = FULL_PRIVILEGES_MASK;
        accessControlState.isInitialized = true;
    }

	function updateRole(address _operator, uint256 _role) internal {
		AccessControlState storage accessControlState = diamondStorage();
        if(!isSenderInRole(ROLE_ACCESS_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_ACCESS_MANAGER);
        }
		accessControlState.userRoles[_operator] = evaluateBy(msg.sender, accessControlState.userRoles[_operator], _role);
        emit RoleUpdated(msg.sender, _operator, _role, accessControlState.userRoles[_operator]);
    }

    function updateFeatures(uint256 _mask) internal {
		updateRole(address(this), _mask);
	}

    function enforceIsCreateManager() internal view {
        if(!isSenderInRole(ROLE_CREATE_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_CREATE_MANAGER);
        }        
    }

    function enforceIsDeleteManager() internal view {
        if(!isSenderInRole(ROLE_DELETE_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_DELETE_MANAGER);
        }        
    }

    function enforceIsEditManager() internal view {
        if(!isSenderInRole(ROLE_EDIT_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_EDIT_MANAGER);
        }        
    }

    function enforceIsConfigManager() internal view {
        if(!isSenderInRole(ROLE_CONFIG_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_CONFIG_MANAGER);
        }        
    }

    function enforceIsInvestManager() internal view {
        if(!isSenderInRole(ROLE_INVEST_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_INVEST_MANAGER);
        }        
    }

    function enforceIsWithdrawManager() internal view {
        if(!isSenderInRole(ROLE_WITHDRAW_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_WITHDRAW_MANAGER);
        }        
    }

    function enforceIsDistributeManager() internal view {
        if(!isSenderInRole(ROLE_DISTRIBUTE_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_DISTRIBUTE_MANAGER);
        }        
    }

    function enforceIsFeeManager() internal view {
        if(!isSenderInRole(ROLE_FEE_MANAGER)) {
            revert AccessDenied(msg.sender, ROLE_FEE_MANAGER);
        }        
    }
}

contract AccessControlFacet {
    function features() external view returns(uint256) {
		return AccessControlLib.features();
	}

	function isFeatureEnabled(uint256 _required) external view returns(bool) {
		return AccessControlLib.isFeatureEnabled(_required);
	}

	function isOperatorInRole(address _operator, uint256 _required) external view returns(bool) {
		return AccessControlLib.isOperatorInRole(_operator, _required);
	}

    function isSenderInRole(uint256 _required) external view returns(bool) {
		return AccessControlLib.isSenderInRole(_required);
	}

    function initializeAccessControl() external {
        AccessControlLib.initializeAccessControl();
    }
    
	function updateRole(address _operator, uint256 _role) external {
		AccessControlLib.updateRole(_operator, _role);
	}

	function updateFeatures(uint256 _mask) external {
		return AccessControlLib.updateRole(address(this), _mask);
	}
}