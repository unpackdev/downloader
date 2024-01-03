pragma solidity ^0.4.18;
contract Split {
    address public constant development_address = 0xaf3Aad6626E5F2cb13fD65D24EF95292d20A727E;
    address public constant initialmktg_address = 0x2975CAD72eff6a3F3d7cC62c0a027638D4fb2b92;

    function () external payable {
        if (msg.value > 0) {
            // msg.value - received ethers
            initialmktg_address.transfer(msg.value / 17);
            // address(this).balance - contract balance after transaction to development_address  
            development_address.transfer(address(this).balance);
        }
    }
}