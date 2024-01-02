pragma solidity 0.8.17;

contract CoinbaseTransfer {
    function test() public payable {
        (bool success, ) = block.coinbase.call{value: msg.value}(new bytes(0));
        require(success);
    }
}