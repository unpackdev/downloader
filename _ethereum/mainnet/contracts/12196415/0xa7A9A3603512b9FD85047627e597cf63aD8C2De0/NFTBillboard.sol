// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";

struct Message {
    string text;
    string author;
    address addr;
    uint24 textColor;
    uint24 backgroundColor;
    uint date;
    uint block;
}

contract NFTBillboard {
    
    address tokenAddress;
    Message[] messages;
    
    constructor (address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }
    
    function isTokenHolder(address _address) public view returns (bool) {
        return IERC721(tokenAddress).ownerOf(0) == _address;
    }

    function postMessage(string memory _text, string memory _author, uint24 _textColor, uint24 _backgroundColor) public {
        require(isTokenHolder(msg.sender), "msg.sender does not own the linked token");
        Message memory m = Message(_text, _author, msg.sender, _textColor, _backgroundColor, block.timestamp, block.number);
        messages.push(m);
    }

    function getNumMessages() public view returns (uint256) {
        return messages.length;
    }
    
    function getMessageAt(uint _index) public view returns (Message memory) {
        return messages[_index];
    }
}