pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract MessageStorage {
    uint256 public msgCount = 0;
    mapping(uint256 => Message) public message;

    struct Message{
        uint256 id;
        string text;
        string fileName;
        string fileType;
        string fileHash;
        string msgSize;
        string datetime;
    }

    function addMessage(string memory text, string memory fileName, string memory fileType, string memory fileHash, string memory msgSize, string memory datetime) public {
        message[msgCount] = Message(msgCount, text, fileName, fileType, fileHash, msgSize, datetime);
        msgCount += 1;
    }

    function addMultipleMessages(string[] memory text, string[] memory fileName, string[] memory fileType, string[] memory fileHash, string[] memory msgSize, string memory datetime) public {
        for(uint i = 0; i< text.length; i++)
        {
            message[msgCount] = Message(msgCount, text[i], fileName[i], fileType[i], fileHash[i], msgSize[i], datetime);
            msgCount += 1;
        }
    }

    function getMessageCount() public view returns (uint256) {
        return msgCount;
    }

    function get(uint256 index) public view returns (Message memory){
        return message[index];
    }
}