// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

contract StoreText {
    
    event PublishEvent(string message);
    
    constructor() public {}
    
    function publishText(string memory message) external {
        emit PublishEvent(message);
    }
}