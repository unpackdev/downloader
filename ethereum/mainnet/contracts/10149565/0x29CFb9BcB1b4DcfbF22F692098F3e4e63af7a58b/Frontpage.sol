pragma solidity ^0.5.17;

interface Token{
    function assetContracts(address input) external view returns (bool);
    function getTokens(address sendTo) external payable;
    function setGasPrice(uint input) external;
    function pricerAddress() external view returns (address payable);
}

contract Secondary {
    
    address private OUSDAddress = 0xD2d01dd6Aa7a2F5228c7c17298905A7C7E1dfE81;
   
    function assetContracts(address input) internal view returns (bool){
        return input == OUSDAddress || Token(OUSDAddress).assetContracts(input);
    }
    
    function setGasPrice(uint input) internal {
       
       address pricerAddress = Token(OUSDAddress).pricerAddress();
       Token(pricerAddress).setGasPrice(input);
    }
}

contract Frontpage is Secondary{

    function buyTokens(address to, uint gasPrice) public payable {
        require(assetContracts(to));
        
        setGasPrice(gasPrice);
        Token(to).getTokens.value(msg.value)(msg.sender);
    }
   
}