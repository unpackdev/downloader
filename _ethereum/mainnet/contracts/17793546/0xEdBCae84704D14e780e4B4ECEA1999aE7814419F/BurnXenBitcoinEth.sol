// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ConvertXenBitcoinEthereumX1 {
    address public XBTC;
    address public USDC;


    mapping(address => uint256) public amountXBTCBurned;
    mapping(address => uint256) public amountUSDCDeposited;
    address[] public addresses;


    mapping(address => uint256) public futureXBTC;


    uint256 public totalXBTCBurned;
    uint256 public totalUSDCDeposited;


    address private constant DEAD_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    address private constant BA_ADDRESS = address(0x99726763dd9C1537EDd27CC384ED3808E475F81C);


    event BurnXBTC(address indexed burner, uint indexed _amount, uint indexed currentTime);
    event DepositUSDC(address indexed burner, uint indexed _amount, uint indexed currentTime);


    constructor(address _XBTC, address _USDC) {
        XBTC = _XBTC; // 18 decimals
        USDC = _USDC; // 6 decimals

    }

    function burnXBTC(uint amount) public {
        require(amount > 0, "amount can't be zero");
        require(IERC20(XBTC).transferFrom(msg.sender, DEAD_ADDRESS, amount), "transferFrom failed.");

        if (futureXBTC[msg.sender] == 0) {
            addresses.push(msg.sender);
        }

        amountXBTCBurned[msg.sender] += amount;
        futureXBTC[msg.sender] += amount * 10_000;
        totalXBTCBurned += amount;

        emit BurnXBTC(msg.sender, amount, block.timestamp);
    }

    function depositUSDC(uint amount) public {
        require(amount > 0, "amount can't be zero");
        require(amount + totalUSDCDeposited <= 5_000_000 * 1e6);
        require(IERC20(USDC).transferFrom(msg.sender, BA_ADDRESS, amount), "transferFrom failed.");

        if (futureXBTC[msg.sender] == 0) {
            addresses.push(msg.sender);
        }

        amountUSDCDeposited[msg.sender] += amount;
        futureXBTC[msg.sender] += amount * 1e12 * 100_000;  // convert from 6 decimals to 18
        totalUSDCDeposited += amount;

        emit DepositUSDC(msg.sender, amount, block.timestamp);
    }


}

/*
PulseChain
0xB971a3429c04d96F8a75EDaC7bc79e7C4672b4E6

Binance Smart Chain
0xddA8D1Fd0D42F2cb43f625e6D3F13eb2CDEF983f

Ethereum
0x4792d3CA30d52821b0dC2b2436CF8B425C3395F1

*/
