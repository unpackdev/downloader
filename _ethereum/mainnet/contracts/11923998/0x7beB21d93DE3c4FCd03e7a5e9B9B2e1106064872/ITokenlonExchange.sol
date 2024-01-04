pragma solidity ^0.5.0;

contract ITokenlonExchange {
    function transactions(bytes32 executeTxHash) external returns (address);
}