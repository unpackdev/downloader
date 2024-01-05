pragma solidity >=0.7.0;



contract testSend {
    
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    
    function doEvent(address _from, address _to, uint256 _amount) public {
        
        emit Transfer( _from, _to, _amount);
       
        
    }
    
    
    
    
}