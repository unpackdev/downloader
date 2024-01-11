// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";

contract MedievalAccessControlCenter is AccessControlEnumerable { 
    bytes32 public constant DAO_ID = keccak256("DAO_ID");
    bytes32 public constant TREASURY_ID = keccak256("TREASURY_ID");
    
    mapping(bytes32 => address) public addressBook;


    constructor(
        address _treasury,
        address _dao
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        if(_treasury == address(0)) {
            _treasury = msg.sender;
        }

        if(_dao == address(0)) {
            _dao = msg.sender;
        }

        _setAddress(TREASURY_ID, _treasury);
        _setAddress(DAO_ID, _dao);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(role != DEFAULT_ADMIN_ROLE, 
            "Cannot change the adminRole of DEFAULT_ADMIN_ROLE!");
        _setRoleAdmin(role, adminRole);
    }

    function _setAddress(bytes32 id, address _address) internal {
        addressBook[id] = _address;
    }

    function setAddress(bytes32 id, address _address) onlyRole(DEFAULT_ADMIN_ROLE) external {
        _setAddress(id, _address);
    }

    function treasury() public view returns(address){
        return addressBook[TREASURY_ID];
    }

    function dao() public view returns(address){
        return addressBook[DAO_ID];
    }
}