// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

contract Round {
    struct RoundInfo {
        uint256 startTime;
        uint256 mintAmount;
        uint256 depositDuration;
        uint256 stakeDuration;
        uint256 totalDeposit;
        uint256 totalWithdrawn;
        uint256 totalReward;
        address depositToken;
        address rewardToken;
    }
}

contract Manager is Ownable, Pausable, Round {
    uint256 public totalRounds;
    mapping(uint256 => RoundInfo) public rounds;

    event RoundStarted(
        uint256 indexed roundId,
        uint256 indexed startTime,
        uint256 indexed duration
    );

    function adminAddRound(uint256 _startTime, uint256 _depositDuration, uint256 _stakeDuration, uint256 _minAmount, address _depositToken, address _rewardToken)
        external
        whenNotPaused()
        onlyOwner()
    {
        RoundInfo memory newRound;
        newRound.startTime = _startTime;
        newRound.mintAmount = _minAmount;
        newRound.depositToken = _depositToken;
        newRound.rewardToken = _rewardToken;
        newRound.depositDuration = _depositDuration;
        newRound.stakeDuration = _stakeDuration;
        rounds[totalRounds] = newRound;
        totalRounds = totalRounds + 1;
    }

    function adminUpdateRound(uint256 _roundId, uint256 _startTime, uint256 _depositDuration, uint256 _stakeDuration)
        external
        whenNotPaused()
        onlyOwner()
    {
        RoundInfo memory round = rounds[_roundId];
        require(0 < round.startTime &&  round.startTime < block.timestamp, "Can-not-update");
        round.startTime = _startTime;
        round.depositDuration = _depositDuration;
        round.stakeDuration = _stakeDuration;
        rounds[_roundId] = round;
    }

    function stop() external onlyOwner() {
        require(!paused(), "Already-paused");
        _pause();
    }

    function start() external onlyOwner() {
        require(paused(), "Already-start");
        _unpause();
    }

}


contract CataLystBridgeERC20 is Manager, ReentrancyGuard {
    using Address for address payable;
    using SafeERC20 for IERC20;

    mapping (address => mapping(uint256 => uint256)) public userFund;
    mapping (address => mapping(uint256 => uint256)) public userWithdrawnFund;
    mapping (address => mapping(uint256 => uint256)) public userReward;

    event UserDeposit(address indexed user, uint indexed roundId, uint indexed amount);
    event UserWithdrawn(address indexed user, uint indexed roundId, uint indexed amount);
   
    modifier isValidRound(uint256 _roundId) {
        require(rounds[_roundId].startTime > 0, "Invalid-round");
        _;
    }

    receive() external payable {
        
    }


    constructor() public  { 
        
    }
    function userDeposit(uint256 _roundId, uint256 _amount) isValidRound(_roundId) external payable whenNotPaused() nonReentrant() { 
        RoundInfo memory round = rounds[_roundId];
        require(round.startTime <= block.timestamp && block.timestamp <= (round.startTime + round.depositDuration),"Can-not-deposit");
        uint fund;
        if(round.depositToken == address(0)) {// round accept ETH
            require(msg.value >= round.mintAmount, "Invalid-fund");
            fund = msg.value;
        } else {
            require(_amount >= round.mintAmount, "Invalid-fund");
            IERC20(round.depositToken).safeTransferFrom(msg.sender, address(this), _amount);
            fund  = _amount;
        } 
    
        userFund[msg.sender][_roundId] = userFund[msg.sender][_roundId] + fund;
        round.totalDeposit = round.totalDeposit + fund;
        rounds[_roundId] = round;
        emit UserDeposit(msg.sender, _roundId, fund);
    }
    
    function userWithDrawn(uint256 _roundId) isValidRound(_roundId) external whenNotPaused()  nonReentrant() {
        RoundInfo memory round = rounds[_roundId];
        uint256 fundOfUser = userFund[msg.sender][_roundId];
        require(fundOfUser > 0, "Invalid fund");
        require((block.timestamp <= round.startTime + round.depositDuration &&  round.totalWithdrawn == 0) ||
                (block.timestamp >= (round.startTime + round.depositDuration + round.stakeDuration) && round.totalWithdrawn > 0), "Can-not-withdrawn-now");
        uint256 amountToWithdrawn;
        uint rewardToUser;
        if (round.totalWithdrawn == 0) {
            amountToWithdrawn = fundOfUser;
            round.totalDeposit = round.totalDeposit - amountToWithdrawn;
            rounds[_roundId] = round;
        } else {
            amountToWithdrawn = fundOfUser * round.totalWithdrawn / round.totalDeposit;
            rewardToUser = fundOfUser * round.totalReward / round.totalDeposit;
            userWithdrawnFund[msg.sender][_roundId] = amountToWithdrawn;
            userReward[msg.sender][_roundId] = rewardToUser;
        }
        if(round.depositToken == address(0)) {
            payable(msg.sender).sendValue(amountToWithdrawn);
        } else { 
            IERC20(round.depositToken).safeTransfer(msg.sender, amountToWithdrawn); // transfer token to user
        }
        IERC20(round.rewardToken).safeTransfer(msg.sender, rewardToUser); // transfer reward to user
        emit UserWithdrawn(msg.sender, _roundId, amountToWithdrawn);
        delete userFund[msg.sender][_roundId];
    }

    function adminCollectFund(uint256 _roundId) isValidRound(_roundId) external onlyOwner() whenNotPaused() {
        require((rounds[_roundId].startTime + rounds[_roundId].depositDuration) < block.timestamp, "Deposit-time-not-end-yet");
        RoundInfo memory round = rounds[_roundId];
        uint256 collectValue = round.totalDeposit;
        if(round.depositToken == address(0)) {
            payable(msg.sender).sendValue(collectValue);
        } else { 
            IERC20(round.depositToken).safeTransfer(msg.sender, collectValue); // transfer token to owner
        }
    }

    function adminDepositFund(uint256 _roundId, uint256 _amount, uint256 _rewardAmount) isValidRound(_roundId) external payable onlyOwner() whenNotPaused() {
        RoundInfo memory round = rounds[_roundId];
        require((round.startTime + round.depositDuration + round.stakeDuration) < block.timestamp, "Round-not-end-yet");
        uint256 depositValue;
        if(round.depositToken == address(0)) {
            depositValue = msg.value;
        } else { 
            IERC20(round.depositToken).safeTransferFrom(msg.sender, address(this), _amount);
            depositValue = _amount;
        }
        IERC20(round.rewardToken).safeTransferFrom(msg.sender, address(this), _rewardAmount);
        round.totalWithdrawn = depositValue;
        round.totalReward = _rewardAmount;
        rounds[_roundId] = round;
    }

    function emergencyWithdawn(address _token) external onlyOwner() whenPaused() {
        if(_token == address(0)) {
            payable(msg.sender).sendValue((address(this).balance));
        } else { 
            uint balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, balance);
        }
        
    }
}
