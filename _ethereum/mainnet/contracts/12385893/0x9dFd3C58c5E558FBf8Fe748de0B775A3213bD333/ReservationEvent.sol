// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IRena.sol";

interface IUniswapV2Router {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract ReservationEvent is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    
    event Claim(address indexed recipient, uint256 indexed claimed);
    event Participated(address indexed sender, uint256 indexed amount, uint256 indexed round);
    event Liquidity(address indexed caller, uint256 indexed ethAmount, uint256 indexed renaAmount);

    IRena rena;

    bool public liquidityGenerated;
    bool public beenInitalized;

    uint256 [5] public reservations;
    uint256 [5] public ethReceived;
    uint256 [5] public participants;
    
    mapping(address => uint256 [5]) public contributions;

    address payable [5] public crew;

    uint256 public startTime;
    uint256 public roundDurations;
    uint256 public endTime;

    constructor() {}

    //Deploy with the start time, and the length of rounds, and the amount of Rena for each round. 
    //Setup for five rounds.
    function initialize(
        address rena_, 
        uint256 startTime_,
        uint256 roundDurations_,
        uint256[5] memory reservations_,
        address payable[5] memory crew_
        ) external onlyOwner {
        require(beenInitalized == false, "Already Initialized");
        beenInitalized = true;
        rena = IRena(rena_);
        startTime = startTime_;
        roundDurations = roundDurations_;
        endTime = startTime.add(roundDurations.mul(5));
        //conveniently split 5 ways.
        for(uint8 i = 0 ; i < 5 ; i++) {
            reservations[i] = reservations_[i] * 1e18;
            crew[i] = crew_[i];
        }
    }
    receive() external payable {
        require(startTime < block.timestamp, "The Reservation Event has not started.");
        require(endTime > block.timestamp, "The Reserveation Event has ended.");
        uint256 round_ = currentRound();
        ethReceived[round_] = ethReceived[round_].add(msg.value);
        if(contributions[msg.sender][round_] == 0) 
            participants[round_] = participants[round_].add(1);
        contributions[msg.sender][round_] = contributions[msg.sender][round_].add(msg.value);
        emit Participated(msg.sender, msg.value, round_);
    }

    function currentRound() public view returns(uint256) {
        return block.timestamp.sub(startTime).div(roundDurations);      
    }

    function reward(address addr) public view returns (uint256 reward_) {
        for(uint8 i = 0 ; i < 5 ; i++) {
            if(ethReceived[i] == 0) continue;
            reward_ = reward_.add(reservations[i]
                                    .mul(contributions[addr][i])
                                        .div(ethReceived[i]));
        }
    }

    function rewardForRound(address addr,   uint8 round_) external view returns(uint256 reward_) {
        if(ethReceived[round_] == 0) return 0;

        reward_ = reward_.add(reservations[round_]
                                .mul(contributions[addr][round_])
                                    .div(ethReceived[round_]));
    }

    function generateLiquidity() public {
        require(block.timestamp > endTime, "The Reservation Event has not concluded yet.");
        require(liquidityGenerated == false, "Already done.");
        liquidityGenerated = true;
        uint256 amount = 3750000*1e18;
        uint256 treasuryCut = address(this).balance.div(10).mul(3);
        //10% of the 30% for On Going Dev.
        rena.treasury().transfer(treasuryCut.div(10));
        //90% remaining split 5 ways to the crew cut.
        treasuryCut = treasuryCut.sub(treasuryCut.div(10)).div(5);
        for(uint8 i = 0; i < 5; i++)
        {    crew[i].transfer(treasuryCut);
        }
        
        rena.approve(rena.uniRouter(), amount);
        uint256 ethAmount = address(this).balance;        
        IUniswapV2Router(rena.uniRouter()).addLiquidityETH
        {value: ethAmount}(
            address(rena),
            amount,
            0,
            0,
            rena.treasury(),
            block.timestamp);
        emit Liquidity(msg.sender, ethAmount, amount);
    }

    function claim() external {
        if(liquidityGenerated == false) {
            generateLiquidity();
        }
        uint256 reward_ = reward(msg.sender);
        require(reward_ > 0, "You have no rewards.");
        delete contributions[msg.sender];
        rena.transfer(msg.sender, reward_);
        emit Claim(msg.sender, reward_);
    }

    function delay(uint256 delay_) external onlyOwner {
        require(startTime > block.timestamp, "It's already started!");
        startTime = startTime.add(delay_);
        endTime = startTime.add(roundDurations.mul(5));
    }
    
    //This is intended to be on the lower end of the gas scale.
    //Front end will have to deisgn the quote but this is ultimately a market buy of LP.
    //Conservative entries should use the main uniswap LP front end.

    function AddClaimToLiquidity() external payable nonReentrant {
        if(liquidityGenerated == false) {
            generateLiquidity();
        } 
        uint256 reward_ = reward(msg.sender);
        require(reward_ > 0, "You have no rewards");
        delete contributions[msg.sender];
        rena.approve(rena.uniRouter(), reward_);
        IUniswapV2Router(rena.uniRouter()).addLiquidityETH{value:msg.value}(
            address(rena),
            reward_,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        emit Claim(msg.sender, reward_);
    }
}
