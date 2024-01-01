pragma solidity ^0.8.22;

interface IMinimalTreasury {

    event Received(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    error ZeroAddress();
    error InsufficientFunds();
    error IdempotencyKeyAlreadyExist(bytes32 idempotencyKey);

    function withdraw(address payable _to, uint256 _amount) external;
}
