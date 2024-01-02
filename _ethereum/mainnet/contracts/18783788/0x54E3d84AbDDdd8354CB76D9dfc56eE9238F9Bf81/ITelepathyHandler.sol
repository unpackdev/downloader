pragma solidity ^0.8.19;

interface ITelepathyHandler {
    function handleTelepathy(uint32 sourceChainId, address sourceSender, bytes memory data) external returns (bytes4);
}
