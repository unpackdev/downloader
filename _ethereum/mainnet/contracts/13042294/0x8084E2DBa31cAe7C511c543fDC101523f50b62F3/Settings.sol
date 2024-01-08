// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./AccessControlEnumerable.sol";

contract Settings is AccessControlEnumerable {
    mapping(bytes32=>uint256) uintSetting;
    mapping(bytes32=>address) addressSetting;

    modifier onlyAdmin() {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
              "Must be admin");
      _;
    }
    
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isAdmin(address _address) public view returns(bool){
      return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function changeAdmin(address adminAddress)
        public onlyAdmin {     
        require(adminAddress != address(0), "New admin must be a valid address");
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function registerNamedRole(string memory _name, address _address) public onlyAdmin {
        bytes32 role = toKey(_name);
        require(!hasRole(role, _address), "Address already has role");
        _setupRole(role, _address);
    }
    function unregisterNamedRole(string memory _name, address _address) public onlyAdmin {
      bytes32 role = toKey(_name);
      require(hasRole(role, _address), "Address already has role");
      revokeRole(role, _address);
    }
    
    function hasNamedRole(string memory _name, address _address) public view returns(bool){
      return hasRole(toKey(_name), _address);
    }
    
    function toKey(string memory _name) public pure returns(bytes32){
      return keccak256(abi.encode(_name));
    }
    function ownerSetNamedUint(string memory _name, uint256 _value) public onlyAdmin{
        ownerSetUint(toKey(_name), _value);
    }
    function ownerSetUint(bytes32 _key, uint256 _value) public onlyAdmin {
        uintSetting[_key] = _value;
    }
    function ownerSetAddress(bytes32 _key, address _value) public onlyAdmin {
        addressSetting[_key] = _value;
    }
    function ownerSetNamedAddress(string memory _name, address _value) public onlyAdmin{
        ownerSetAddress(toKey(_name), _value);
    }
    
    function getUint(bytes32 _key) public view returns(uint256){
        return uintSetting[_key];
    }
    
    function getAddress(bytes32 _key) public view returns(address){
        return addressSetting[_key];
    }

    function getNamedUint(string memory _name) public view returns(uint256){
        return getUint(toKey(_name));
    }
    function getNamedAddress(string memory _name) public view returns(address){
        return getAddress(toKey(_name));
    }
    function removeNamedUint(string memory _name) public onlyAdmin {
      delete uintSetting[toKey(_name)];
    }
    function removeNamedAddress(string memory _name) public onlyAdmin {
      delete addressSetting[toKey(_name)];
    }
}
