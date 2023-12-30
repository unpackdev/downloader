pragma solidity ^0.6.2;


interface ITransferContarctCallback {

  function tokenFallback(address _from, address _to,  uint _value) external;

}


contract TestCallback is ITransferContarctCallback {
    
    
    uint256 public amount = 0;
    
    address public fromAddr = address(0x0);
    
    address public toAddr = address(0x0);
    
    function tokenFallback(address _from, address _to,  uint _value) override external {
        toAddr = _to;
        fromAddr = _from;
        amount = _value;
    }


}