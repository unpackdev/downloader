/* 
 *  ProxyCat
 *  VERSION: 1.1
 *
 */

pragma solidity ^0.6.0;

contract ProxyCatLedger{ 
    
    function getKitty(string memory family,string memory label) public view returns(address){}
    
}

contract ProxyKitty {
    
      function feed() public view returns (string memory) {}
      function feed(address target) public view returns (string memory) {}
      function feed(address target,address target2) public view returns (string memory) {}
      function feed(address target,address target2,address target3) public view returns (string memory) {}
      function feed(string memory label) public view returns (string memory) {}
      function feed(string memory label,string memory label2) public view returns (string memory) {}
      function feed(string memory label,string memory label2,string memory label3) public view returns (string memory) {}
      function feed(uint256 number) public view returns (string memory) {}
      function feed(uint256 number,uint256 number2) public view returns (string memory) {}
      function feed(uint256 number,uint256 number2,uint256 number3) public view returns (string memory) {}
      function feed(address target,uint256 number,uint256 number2) public view returns (string memory) {}
      function feed(string memory label,uint256 number,uint256 number2) public view returns (string memory) {}
      function feed(address target,address taget2,uint number,uint number2) public view returns (string memory) {}
      function feed(string memory label,string memory label2,uint number,uint number2) public view returns (string memory) {}
      function feed(address target,string memory label2,uint number,uint number2) public view returns (string memory) {}
      function feed(bytes32 data) public view returns (string memory) {}
      
}

contract ProxyCat{ 
    
    
    string public version="1.1";
    
    address public ledger=0x15fEF21821F049Bc8f3fD6389da5dD34BeDD1Bfc;

      function cat(string memory family,string memory label) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed();
      }
      
      function cat(string memory family,string memory label,address target) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(target);
      }
      
      function cat(string memory family,string memory label,address target,address target2) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(target,target2);
      }
      
      function cat(string memory family,string memory label,address target,address target2,address target3) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(target,target2,target3);
      }
      
      
      function cat(string memory family,string memory label,string memory text) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(text);
      }
      
      function cat(string memory family,string memory label,string memory text,string memory text2) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(text,text2);
      }
      
      function cat(string memory family,string memory label,string memory text,string memory text2,string memory text3) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(text,text2,text3);
      }
      
      
      
      function cat(string memory family,string memory label,uint number) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(number);
      }
      
      function cat(string memory family,string memory label,uint number,uint number2) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(number,number2);
      }      
      
      function cat(string memory family,string memory label,uint number,uint number2,uint number3) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(number,number2,number3);
      }    
      
      
      
          
      function cat(string memory family,string memory label,address target,uint number,uint number2) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(target,number,number2);
      } 
      
      function cat(string memory family,string memory label,string memory text,uint number,uint number2) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(text,number,number2);
      } 
      
      
      
      
      function cat(string memory family,string memory label,address target,address target2,uint number,uint number2) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(target,target2,number,number2);
      } 
      
      function cat(string memory family,string memory label,string memory text,string memory text2,uint number,uint number2) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(text,text2,number,number2);
      } 

    
      function cat(string memory family,string memory label,address target,string memory text,uint number,uint number2) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(target,text,number,number2);
      } 
      
      function cat(string memory family,string memory label,bytes32 data) public view returns (string memory) {
          return ProxyKitty(getKitty(family,label)).feed(data);
      }
      
      function getKitty(string memory family,string memory label)internal view returns(address){
          return ProxyCatLedger(ledger).getKitty(family,label);
      }

}