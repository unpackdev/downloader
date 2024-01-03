pragma solidity ^0.7.4;

contract UniswapPriceOracleStorage {
    address public implementation;
    address public admin;
    address public pendingAdmin;
    uint Q112 = 2**112;
    uint public constant PERIOD = 10 minutes;
}