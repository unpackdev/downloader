pragma solidity ^0.4.0;

contract Airdrop {

    function batch(address token, address []toAddr, uint256 []value) returns (bool){

        require(toAddr.length == value.length && toAddr.length >= 1);

        bytes4 fID= bytes4(keccak256("transferFrom(address,address,uint256)"));

        for(uint256 i = 0 ; i < toAddr.length; i++){

        if(!token.call(fID, msg.sender, toAddr[i], value[i])) { revert(); }
        }
    }
}