// SPDX-License-Identifier: MIT
/*

Contract for the LobsterLand server subscription system

@mintertale
*/

import "./Ownable.sol";

pragma solidity ^0.8.0;

contract LobsterLand {
	event Subscribes(address indexed _address, uint256 indexed _discordId, uint256 _expired, uint256 _payed);

    address   public owner; //creator contract
	address   public lobster;
    uint256   public price = 9 * 10**16; // 0.09

    mapping (uint256 => uint256) data;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender || lobster == msg.sender, "Ownership Assertion: Caller of the function is not the owner.");
    _;
    }

    function buyAlpha(uint256 _discordId) public payable  {
        require(msg.value > 0, "You need set amount");
		require(_discordId > 10**16, "You need set discord ID");
        uint monthCounter = 1;
        uint256 expired;
        if(msg.value > price){
            monthCounter = uint(msg.value/price);
        }

        if (data[_discordId] > 0){
            expired = data[_discordId];
        } else {
            expired = block.timestamp;
        }
    
        data[_discordId] = 86400 * 30 * monthCounter + expired;
		
		emit Subscribes(msg.sender,  _discordId, 86400 * 30 * monthCounter + expired, msg.value);

    }


    function getExpiredStatus(uint256 _discordId) external view returns (bool status){
        status = true;
        if (block.timestamp < data[_discordId]){
            status = false;
        }
    }

    function getExpiredTime(uint256 _discordId) external view returns (uint256 time){
        time = data[_discordId];
    }

    function withdraw(address _toaddress) external onlyOwner {
        address payable _to = payable(_toaddress);
        _to.transfer(address(this).balance);
    }

	function setLobster(address _address) external onlyOwner {
		lobster = _address;
	}

	function setExpireSub(uint256 _discordId) public onlyOwner {
		data[_discordId] = block.timestamp;
	}

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }


    function setSubscribe(uint256 _discordId, uint16 _countDays) public onlyOwner {
        uint256 expired = data[_discordId];
        if (expired == 0){
            expired = block.timestamp;
        }
        data[_discordId] = expired + 86400 * _countDays;
		emit Subscribes(address(0x00), _discordId , expired + 86400 * _countDays, 0);
    }


	receive() external payable {
		
    }

    function balance() external view returns (uint256 amount){
        amount = address(this).balance;
    }

}
