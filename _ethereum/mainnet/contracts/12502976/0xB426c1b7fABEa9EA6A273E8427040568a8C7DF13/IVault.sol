pragma solidity ^0.5;

interface IVault {
    
    function submitTransaction(address destination, uint value, bytes calldata data) external returns (uint);

}