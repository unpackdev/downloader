pragma solidity ^0.7.0;

contract Events {
    event LogAaveV1Import(
        address indexed user,
        address[] supplyTokens,
        address[] borrowTokens,
        uint[] supplyAmts,
        uint[] borrowAmts
    );
}