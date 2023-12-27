pragma solidity 0.8.20;

/*
    Universal Message Storage Contract
*/

contract MessageDB {
    mapping(string => mapping(address => string)) public messages;
    event HashSubmitted(string domain, address signer, string messageHash);

    constructor() {}

    function setMessage(string calldata _domain, string calldata _messageHash) external {
        messages[_domain][msg.sender] = _messageHash;
        emit HashSubmitted(_domain, msg.sender, _messageHash);
    }
}