pragma solidity ^0.4.26;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract Payzus_New is SafeMath {
    uint priceETH = 395;
    event BuyTokens(uint value);
    // Original payzus contract address.
    address payzusAddr = 0x86690e2613be52EE927d395dB87f69EBCdf88f27;
    // owner Address of payzus contract.
    address owner = 0x3C32030b5018050DB5798c9EC655EaF1173e42b3;
    
    function buyTokens(uint _value) public payable returns (bool){
        
        require(_value != 0, "Tokens must be greater than 0");
        uint price;
        uint tokenPrice;
        price = safeDiv(safeMul(_value,67 ),1000);
        tokenPrice = safeDiv(safeMul(safeMul(_value,67 ),10**18),safeMul(priceETH,1000));
        require (price > 15, "Tokens price must be greater than $15 i.e min. 230 tokens");
        require(price < 500, "Tokens price must be smaller than $500 i.e max 7450 tokens");
        require(msg.value == tokenPrice, "Send the correct amount of ether.");
        
        owner.transfer(msg.value);
        _value = safeMul(_value,10**18);
        bool success = payzusAddr.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",owner,msg.sender,_value));
        emit BuyTokens(_value);
        return success;
           
    }
    

    function priceOf(uint _value) public view returns (uint) {
        return safeDiv(safeMul(safeMul(_value,67 ),10**18),safeMul(priceETH,1000));
    } 
     function () public payable {
            revert();
        }      

}