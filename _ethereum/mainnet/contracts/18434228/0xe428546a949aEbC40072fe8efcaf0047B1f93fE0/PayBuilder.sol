pragma solidity ^0.8.0;

contract PayBuilder {
    function payBuilder() public payable {
        block.coinbase.transfer(msg.value);
    }
}