// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "./Ownable.sol";

contract GasChat is Ownable {
  event NewMessage(address indexed from, uint timestamp, string message, uint _style);
  event NewAlias(address indexed from, string _alias, string _url);

  uint[3] public prices = [0.000005 ether, 0.00005 ether, 0.0001 ether];

  struct Message {
    address waver;
    string message;
    uint timestamp;
    uint _style;
  }

  Message[] messages;

  struct User {
    address id;
    string _alias;
    string _url;
    bool exists;
  }
  mapping (address => User) public user;
  address[] public userAddresses;

  constructor() payable {}

  function setMessage(string memory _message, uint _style) public payable {
    uint msgLength = bytes(_message).length;
    require((msg.value >= msgLength * prices[_style] && msgLength < 281) || owner() == msg.sender);
    messages.push(Message(msg.sender, _message, block.timestamp, _style));
    emit NewMessage(msg.sender, block.timestamp, _message, _style);
  }

  function getAllMessages() view public returns (Message[] memory) {
    return messages;
  }

  function setAlias(string memory _alias, string memory _url) public payable {
    uint aliasLength = bytes(_alias).length;
    uint urlLength = bytes(_url).length;
    require(aliasLength < 21 && urlLength < 81);    
    if(!user[msg.sender].exists) {
      require(msg.value > 0.0299 ether || owner() == msg.sender);    
      userAddresses.push(msg.sender);
    }
    user[msg.sender] = User({id: msg.sender, _alias: _alias, _url: _url, exists: true });
    emit NewAlias(msg.sender, _alias, _url);
  }

  function getAllAliases() public view returns (User[] memory){
    User[] memory ret = new User[](userAddresses.length);
    for (uint i = 0; i < userAddresses.length; i++) {
      ret[i] = User({
        id: user[userAddresses[i]].id,
        _alias: user[userAddresses[i]]._alias,
        _url: user[userAddresses[i]]._url,
        exists: true
      });
    }
    return ret;
  }

  function withdrawFunds() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}