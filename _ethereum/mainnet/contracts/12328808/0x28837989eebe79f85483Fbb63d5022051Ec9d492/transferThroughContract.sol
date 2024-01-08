pragma solidity ^0.7.0;


contract transferThroughContract {
    function transferTo(address payable _to) public payable {
        _to.send(msg.value);
    }
}