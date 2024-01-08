pragma solidity >=0.8.0;

contract FlashBotsPlay {

    function x() external payable{
        block.coinbase.transfer(msg.value);
    }
}