//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Clones.sol";
import "./Ownable.sol";
import "./IAccessControl.sol";
import "./AccessControl.sol";

interface IPollyModule {

  struct ModuleInfo {
    string name;
    address implementation;
    bool clone;
  }

  function init(address for_) external;
  function didInit() external view returns(bool);
  function getModuleInfo() external returns(IPollyModule.ModuleInfo memory module_);
  function setString(string memory key_, string memory value_) external;
  function setUint(string memory key_, uint value_) external;
  function setAddress(string memory key_, address value_) external;
  function setBytes(string memory key_, bytes memory value_) external;
  function getString(string memory key_) external view returns(string memory);
  function getUint(string memory key_) external view returns(uint);
  function getAddress(string memory key_) external view returns(address);
  function getBytes(string memory key_) external view returns(bytes memory);

}


contract PollyModule is AccessControl {

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bool private _did_init = false;
  mapping(string => string) private _keyStoreStrings;
  mapping(string => uint) private _keyStoreUints;
  mapping(string => bytes) private _keyStoreBytes;
  mapping(string => address) private _keyStoreAddresses;

  constructor(){
    init(msg.sender);
  }

  function init(address for_) public virtual {
    require(!_did_init, 'CAN_NOT_INIT');
    _did_init = true;
    _grantRole(DEFAULT_ADMIN_ROLE, for_);
    _grantRole(MANAGER_ROLE, for_);
  }

  function didInit() public view returns(bool){
    return _did_init;
  }

  function setString(string memory key_, string memory value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _keyStoreStrings[key_] = value_;
  }
  function setUint(string memory key_, uint value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _keyStoreUints[key_] = value_;
  }
  function setAddress(string memory key_, address value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _keyStoreAddresses[key_] = value_;
  }
  function setBytes(string memory key_, bytes memory value_) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _keyStoreBytes[key_] = value_;
  }
  function getString(string memory key_) public view returns(string memory) {
    return _keyStoreStrings[key_];
  }
  function getUint(string memory key_) public view returns(uint) {
    return _keyStoreUints[key_];
  }
  function getAddress(string memory key_) public view returns(address) {
    return _keyStoreAddresses[key_];
  }
  function getBytes(string memory key_) public view returns(bytes memory) {
    return _keyStoreBytes[key_];
  }

}
