pragma solidity ^0.7.0;

contract SubgraphTester {

    event EventSubmitted(address indexed _sender);

    function submitEvent() public {
        emit EventSubmitted(msg.sender);
    }
}