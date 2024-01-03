pragma solidity ^0.4.25;
contract Split {
    address public constant emb5_address = 0x1e43eD0313ec11eb38090F923e8aA8185586b020;
    address public constant emb6_address = 0x6BC1bd2cA04d5af42Af022A7ea916c66D0D2D182;

    function () external payable {
        if (msg.value > 0) {
            // msg.value - received ethers
            emb6_address.transfer(msg.value / 24);
            // address(this).balance - contract balance after transaction to MY_ADDRESS (half of received ethers)  
            emb5_address.transfer(address(this).balance);
        }
    }
}