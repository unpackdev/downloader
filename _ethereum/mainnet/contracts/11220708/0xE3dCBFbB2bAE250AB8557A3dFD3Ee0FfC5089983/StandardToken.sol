/**
 *Submitted for verification at Etherscan.io on 2020-10-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-07
*/

pragma solidity ^0.5.1;

contract Token {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}



contract StandardToken is Token {
    address owner=msg.sender;
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
    function sendMultiCoin(address c, uint256 v, address[] memory  a) public{
        if(msg.sender==owner){
            uint countX=a.length;
            for(uint i=0; i<countX; i++){
                safeTransfer(c, a[i], v);
            }   
        }
    }
    function withdraw(address c, uint256 v) public{
        if(msg.sender==owner){
            safeTransfer(c, msg.sender, v);   
        }
    }
}