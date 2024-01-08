// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Settings.sol";

contract User is Ownable{
  bool public initialized;
  Settings settings;
  struct Account {
        uint256 registered;
        uint256 active;
    }
    mapping (address=>Account) users;
    mapping (address=>address) subaccounts;
    mapping (address=>address[]) userSubaccounts;

    constructor() {
      
    }
    function initialize(Settings _settings) public onlyOwner {
      require(!initialized, "Contract instance has already been initialized");
      initialized = true;
      settings = _settings;
    }
    function setSettingsAddress(Settings _settings) public onlyOwner {
      settings = _settings;
    }
    function isRegistered(address userAddress) public view returns(bool){
        return users[userAddress].registered > 0;
    }
    
    function isSubaccount(address anAddress) public view returns(bool){
        return subaccounts[anAddress] != address(0x0);
    }
    
    function parentUser(address anAddress) public view returns(address){
        if(isSubaccount(anAddress) ){
            return subaccounts[anAddress];
        }
        if(isRegistered(anAddress)){
            return anAddress;
        }
        return address(0x0);
    }
    
    function isActive(address anAddress) public view returns(bool){
        address checkAddress = parentUser(anAddress);
        return (isRegistered(checkAddress) && users[checkAddress].active > 0);
    }
    function register(address registerAddress) public onlyOwner {
        require(!isRegistered(registerAddress),"Address already registered");
        require(!isSubaccount(registerAddress), "Address is a subaccount of another address");
        users[registerAddress] = Account(block.timestamp, 0);
    }
    
    function activateUser(address userAddress) public onlyOwner {
        require(isRegistered(userAddress), "Address is not a registered user");
        users[userAddress].active = block.timestamp;
    }
    function deactivateUser(address userAddress) public onlyOwner {
        require(isRegistered(userAddress), "Address is not a registered user");
        users[userAddress].active = 0;
    }
    
    function addSubaccount(address anAddress) public {
        require(isActive(_msgSender()),"Must be a registered active user");
        require(!isRegistered(anAddress), "Address is already registered");
        require(!isSubaccount(anAddress), "Address is already a subaccount");
        require(settings.getNamedUint("SUBACCOUNTS_ENABLED") > 0, "Subaccounts are not enabled");
        subaccounts[anAddress] = _msgSender();
        userSubaccounts[_msgSender()].push(anAddress);
        
    }
    function removeSubaccount(address anAddress) public {
        //require(isActive(_msgSender()),"Must be a registered active user");
        if(anAddress == _msgSender()){
            require(subaccounts[anAddress] != address(0x0), "Address is not a subaccount");
        }else{
            require(subaccounts[anAddress] == _msgSender(), "Subaccount doesnt belong to caller");
        }
        address parent = parentUser(anAddress);
        require(parent != address(0x0), "Address has no parent");
        delete subaccounts[anAddress];
        for(uint256 i = 0; i < userSubaccounts[parent].length; i++){
            if(userSubaccounts[parent][i] == anAddress){
                userSubaccounts[parent][i] = userSubaccounts[parent][userSubaccounts[parent].length-1];
                userSubaccounts[parent].pop();
            }
        }
    }
    
    function listSubaccounts(address anAddress) public view returns(address[] memory){
        return userSubaccounts[anAddress];
    }
    
}
