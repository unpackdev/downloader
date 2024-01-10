// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

interface IRandom {
    function pickPowerup(address _hunter) external view returns (uint8);
}

contract Powerup is ERC1155, Ownable {

  IRandom public random;

  string public name;
  string public symbol;

  mapping(uint => string) public tokenURI;
  mapping(address => bool) public managers;

  constructor() ERC1155("") {
    name = "Powerups";
    symbol = "POWERUPS";
  }

//   ==== Modifiers ====

  modifier manager() {
    require(managers[msg.sender] == true, "This address is not allowed to interact with the contract");
    _;
  }

//   ==== Public View Functions ====

    function uri(uint _id) public override view returns (string memory) {
        return tokenURI[_id];
    }

//   ==== External Functions ====

  function mintPowerup(address _to) external manager {
    uint8 _id = random.pickPowerup(_to);
    _mint(_to, _id, 1, "");
  }

  function burn(address _from, uint _id, uint _amount) external manager {
    _burn(_from, _id, _amount);
  }

//   ==== Admin Functions ====

  function setURI(uint _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }  

  function addManager(address _address) external onlyOwner {
        managers[_address] = true;
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
    }

    function setRandom(address _random) external onlyOwner { 
        random = IRandom(_random); 
    }

}