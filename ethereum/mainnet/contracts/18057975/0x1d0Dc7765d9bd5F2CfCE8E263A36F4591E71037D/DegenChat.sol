// SPDX-License-Identifier: MIT

/*
 $$$$$$\   $$$$$$\        $$$$$$$\  $$$$$$$$\  $$$$$$\  $$$$$$$$\ $$\   $$\        $$$$$$\  $$\   $$\  $$$$$$\$$$$$$$$\ 
$$  __$$\ $$  __$$\       $$  __$$\ $$  _____|$$  __$$\ $$  _____|$$$\  $$ |      $$  __$$\ $$ |  $$ |$$  __$$\__$$  __|
$$ /  $$ |$$ /  \__|      $$ |  $$ |$$ |      $$ /  \__|$$ |      $$$$\ $$ |      $$ /  \__|$$ |  $$ |$$ /  $$ | $$ |   
$$ |  $$ |$$ |$$$$\       $$ |  $$ |$$$$$\    $$ |$$$$\ $$$$$\    $$ $$\$$ |      $$ |      $$$$$$$$ |$$$$$$$$ | $$ |   
$$ |  $$ |$$ |\_$$ |      $$ |  $$ |$$  __|   $$ |\_$$ |$$  __|   $$ \$$$$ |      $$ |      $$  __$$ |$$  __$$ | $$ |   
$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$ |      $$ |  $$ |$$ |      $$ |\$$$ |      $$ |  $$\ $$ |  $$ |$$ |  $$ | $$ |   
 $$$$$$  |\$$$$$$  |      $$$$$$$  |$$$$$$$$\ \$$$$$$  |$$$$$$$$\ $$ | \$$ |      \$$$$$$  |$$ |  $$ |$$ |  $$ | $$ |   
 \______/  \______/       \_______/ \________| \______/ \________|\__|  \__|       \______/ \__|  \__|\__|  \__| \__|   */                                                                                                                                                                                   

/* The Original Blockchain Chat by DapperLad.
More Fun dApps and experiences at: https://dapperlad.xyz */

pragma solidity ^0.8.0;

contract DegenChat {
    address public owner;
    
    struct Message {
        address sender;
        string username;
        string content;
        uint256 timestamp;
    }

    event NewMessage(address indexed sender, string username, string content, uint256 timestamp); // Updated event to include timestamp

    Message[] public messages;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function sendMessage(string memory _username, string memory _content) public payable {
        require(msg.value == 0.0069 ether, "Send 0.0069 ether to send a message");
        require(bytes(_content).length <= 280, "Message too long");

        Message memory newMessage = Message(msg.sender, _username, _content, block.timestamp);
        messages.push(newMessage);

         emit NewMessage(msg.sender, _username, _content, block.timestamp);
    }


    function getRecentMessages(uint limit) public view returns (Message[] memory recentMessages) {
        uint totalMessages = messages.length;
        if (totalMessages < limit) {
            limit = totalMessages;
        }

        recentMessages = new Message[](limit);

        for (uint i = 0; i < limit; i++) {
            recentMessages[i] = messages[totalMessages - 1 - i];
        }
        return recentMessages;
    }

    function sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
}