pragma solidity ^0.8.7;
contract Bribe {
    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }
}