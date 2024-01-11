// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

import "./IMedievalAccessControlCenter.sol";

contract MedievalAccessControlled {   
    string constant ACCESS_DENIED_MSG = "Access Denied!"; 
    
    bytes32 constant DEFAULT_ADMIN_ROLE = 0;

    IMedievalAccessControlCenter public controlCenter;
    
    // tempAdmin has all the priviledge, and it is only used when controlCenter is not set.
    address public tempAdmin; 

    function _setControlCenter(address _controlCenter, address _tempAdmin) internal {
        controlCenter = IMedievalAccessControlCenter(_controlCenter);
        if(_controlCenter == address(0)){
            tempAdmin =_tempAdmin;
        } else {
            tempAdmin = address(0);
            // Prevent setting controlCenter to an invalid address.
            require(
                controlCenter.getRoleMemberCount(DEFAULT_ADMIN_ROLE) > 0,
                "Invalid controlCenter address!"
            ); 
        }
    }

    function setControlCenter(address _controlCenter, address _tempAdmin) external onlyAdmin {
        _setControlCenter(_controlCenter, _tempAdmin);
    }

    function _hasRole(bytes32 role, address account) internal view returns(bool){
        return controlCenter.hasRole(role, account);
    }

    function _treasury() internal view returns(address){
        return controlCenter.treasury();
    }

    function _dao() internal view returns(address){
        return controlCenter.dao();
    }

    modifier onlyRole(bytes32 role) {
        if(address(controlCenter) == address(0)) {
            require(tempAdmin == msg.sender, ACCESS_DENIED_MSG);
        } else {
            require(_hasRole(role, msg.sender),
                ACCESS_DENIED_MSG);
        }
        _;
    }

    modifier onlyAdmin() {
        if(address(controlCenter) == address(0)) {
            require(tempAdmin == msg.sender, ACCESS_DENIED_MSG);
        } else {
            require(_hasRole(0, msg.sender),
                ACCESS_DENIED_MSG);
        }
        _;
    }

}