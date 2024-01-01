// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Forwarder {
    address public owner;
    mapping(address => bool) public authorizedCallers;
    mapping(address => bool) public authorizedTokens;

    event Forward(address indexed caller, address indexed recipient, address indexed token, uint256 amount);

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only the owner can transfer ownership");
        owner = newOwner;
    }

    function authorizeCaller(address caller, bool authorize) public {
        require(msg.sender == owner, "Only the owner can authorize callers");
        authorizedCallers[caller] = authorize;
    }

    function authorizeToken(address token, bool authorize) public {
        require(msg.sender == owner, "Only the owner can authorize tokens");
        authorizedTokens[token] = authorize;
    }

    // payable function which forwards eth to address recipient
    function forward(address recipient) public payable {
        require(authorizedCallers[msg.sender], "Only authorized callers can forward");
        (bool success, ) = recipient.call{value: msg.value}("");
        require(success, "Forward failed");
        emit Forward(msg.sender, recipient, address(0), msg.value);
    }

    // function with forwards address erc20 to address recipient
    function forwardToken(address token, address recipient, uint256 amount) public {
        require(authorizedCallers[msg.sender], "Only authorized callers can forward");
        require(authorizedTokens[token], "Only authorized tokens can be forwarded");
        (bool success, ) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, recipient, amount));
        require(success, "Forward failed");
        emit Forward(msg.sender, recipient, token, amount);
    }

    // catch the erc20 token and send it to recipient (uses more gas)
    function bounceToken(address token, address recipient, uint256 amount) public {
        require(authorizedCallers[msg.sender], "Only authorized callers can forward");
        require(authorizedTokens[token], "Only authorized tokens can be forwarded");
        (bool success, ) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
        require(success, "Receive failed");
        (success, ) = token.call(abi.encodeWithSignature("transfer(address,uint256)", recipient, amount));
        require(success, "Forward failed");
        emit Forward(msg.sender, recipient, token, amount);
    }
}
