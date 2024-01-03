pragma solidity ^0.5.16;

contract XFlag {
    
    event Flag( uint8 data );
    
    function setFlag(uint8 data) public
    {
        emit  Flag(data);       
    }
    
}