pragma solidity 0.5.1;

contract Bribe {

    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }

    
}