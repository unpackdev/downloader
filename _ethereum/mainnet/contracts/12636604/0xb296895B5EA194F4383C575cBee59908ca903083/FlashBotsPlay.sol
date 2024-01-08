pragma solidity >=0.8.0;

contract FlashBotsPlay {
    
    uint public z;

    function reset() external {
        z = 0;
    }

    function x() external payable{
        z = 0;
        z = 3;
        block.coinbase.transfer(msg.value);
    }
}