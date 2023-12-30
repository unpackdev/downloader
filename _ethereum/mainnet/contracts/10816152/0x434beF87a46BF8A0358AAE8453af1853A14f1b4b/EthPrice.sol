pragma solidity >=0.4.23 <0.6.0;

contract EthPrice{
    
    uint public ethereumPrice=345000000000000000000;
    address owner = 0x2108e4f2850c003D7B9e9A765a0A57176b8103af;
    
    constructor() public{
        
    }
    
    
    function setEthPrice(uint price) public{
        require(msg.sender==owner,"Only Admin Can Call");
        ethereumPrice = price;
    }
    
    function ETHUSDPrice() public view returns (uint){
        return ethereumPrice;
    }
    
    
}