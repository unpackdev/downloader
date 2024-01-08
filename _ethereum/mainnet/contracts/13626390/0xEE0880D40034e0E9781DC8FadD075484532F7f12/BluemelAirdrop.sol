pragma solidity ^0.6.0;

import "Bluemel.sol";

contract BluemelAirdrop {

    Bluemel public token;
    mapping(address => bool) public alreadyReceived;

    constructor(
        address _tokenAddr
    ) public {
        token = Bluemel(_tokenAddr);
    }

    function gruessGernot() public {
        require(!alreadyReceived[msg.sender], "Sie haben den Airdrop bereits erhalten");
        alreadyReceived[msg.sender] = true;
        token.transfer(msg.sender, 100000000000000000000); //18 decimals token
    }
    function hasAlreadyAirdrop(address add) public returns(bool) {
        if(alreadyReceived[add]) {
            return true;
        } else {
            return false;
        }
    }
}