// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

// .___                           .__        __  .__
// |   | ____   ______ ___________|__|______/  |_|__| ____   ____
// |   |/    \ /  ___// ___\_  __ \  \____ \   __\  |/  _ \ /    \
// |   |   |  \\___ \\  \___|  | \/  |  |_> >  | |  (  <_> )   |  \
// |___|___|  /____  >\___  >__|  |__|   __/|__| |__|\____/|___|  /
//          \/     \/     \/         |__|                       \/
//
// Powered by ArcBlock (https://github.com/blocklet/inscription)

contract Inscription {
  address public owner;
  uint256 private messageCount = 0;
  mapping(uint256 => string) private messages;
  event RecordedMessage(uint256 indexed index, string message);

  modifier onlyOwner() {
    require(msg.sender == owner, 'Only the owner can call this function.');
    _;
  }

  modifier messageNotEmpty(string memory message) {
    require(bytes(message).length > 0, 'Message cannot be empty.');
    _;
  }

  constructor(string memory firstMessage) {
    owner = msg.sender;
    recordMessage(firstMessage);
  }

  function recordMessage(string memory message) public onlyOwner messageNotEmpty(message) {
    messages[messageCount] = message;
    emit RecordedMessage(messageCount, message);
    messageCount++;
  }

  function getMessage(uint256 index) public view returns (string memory) {
    require(index >= 0 && index <= messageCount, 'Invalid message index.');
    return messages[index];
  }

  function getAllMessage() public view returns (string[] memory) {
    string[] memory allMessage = new string[](messageCount);
    for (uint256 i = 0; i < messageCount; i++) {
      allMessage[i] = messages[i];
    }
    return allMessage;
  }
}
