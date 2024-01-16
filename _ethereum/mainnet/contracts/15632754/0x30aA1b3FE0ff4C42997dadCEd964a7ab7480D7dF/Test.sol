contract Test {
    function test() public view returns (address) {
        return block.coinbase;
    }
}