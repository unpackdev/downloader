pragma solidity ^0.5.16;

contract nos{
    
    uint256 public a =1;
    address public testAddress ;
    function setNumber(uint256 num) public{
        testAddress = msg.sender;
        a = num;
    }
    
    function getNumber() public view returns(uint256){
        return a;
    }
    
    
    function getSender(int b) public view returns(int bb,uint256 n, address m){
        n=a;
        bb=b;
        m=msg.sender;
    }
}