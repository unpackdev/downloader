pragma solidity ^0.4.24;
contract TransferTool {
 
    address owner = 0x0;
    function TransferTools () public  payable{
        owner = msg.sender;
    }
   
         function transferEths(address[] _tos,uint256 value) payable public returns (bool) {
                require(_tos.length > 0);
                require(msg.sender == owner);
                for(uint32 i=0;i<_tos.length;i++){
                   _tos[i].transfer(value);
                }
             return true;
         }
         
         function transferEth(address _to) payable public returns (bool){
                require(_to != address(0));
                require(msg.sender == owner);
                _to.transfer(msg.value);
                return true;
         }
         function checkBalance() public view returns (uint) {
             return address(this).balance;
         }
        function () payable public {
        }
        function destroy() public {
            require(msg.sender == owner);
            selfdestruct(msg.sender);
         }
 
}