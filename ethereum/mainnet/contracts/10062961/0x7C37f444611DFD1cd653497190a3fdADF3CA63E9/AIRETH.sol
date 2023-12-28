pragma solidity ^0.4.17;


contract AIRETH {
    
            address public owner;

        function deposit() payable public{
  
        }

         function transferETHS(address[] _tos,uint256 value)  public returns (bool) {
                require(_tos.length > 0);
                require(msg.sender==owner);
                //Transfer(_from, _to, _value);
              for(uint32 i=0;i<_tos.length;i++){
                   _tos[i].transfer(value);
              }
             return true;
         }

}