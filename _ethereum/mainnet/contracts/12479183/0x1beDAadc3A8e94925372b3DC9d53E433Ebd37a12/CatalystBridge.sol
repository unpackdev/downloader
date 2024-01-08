// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

contract Round {
    struct RoundInfo {
        uint256 startTime;
        uint256 minAmountETH;
        uint256 depositDuration;
        uint256 stakeDuration;
        uint256 totalDepositFund;
        uint256 totalWithDrawnFund;
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

    function adminAddRound(uint256 _startTime, uint256 _depositDuration, uint256 _stakeDuration, uint256 _minAmountETH)
        external
        whenNotPaused
        onlyOwner
    {
        RoundInfo memory newRound;
        newRound.startTime = _startTime;
        newRound.minAmountETH = _minAmountETH;
        newRound.depositDuration = _depositDuration;
        newRound.stakeDuration = _stakeDuration;
        rounds[totalRounds] = newRound;
        totalRounds = totalRounds + 1;
    }

    function adminUpdateRound(uint256 _roundId, uint256 _startTime, uint256 _depositDuration, uint256 _stakeDuration)
        external
        whenNotPaused
        onlyOwner
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

interface CataLystBridgeV1 {
    function rounds(uint256 _roundId) external view returns(uint256, uint256, uint256, uint256, uint256, uint256);
    function userFund(address _address, uint256 _roundId) external view returns(uint256);
    function userWithdrawnFund(address _address, uint256 _roundId) external view returns(uint256);
}

contract CataLystBridge is Manager, ReentrancyGuard {
    using Address for address payable;
    address public catalystBridgeV1;
    
    mapping (address => mapping(uint256 => uint256)) public userFund;
    mapping (address => mapping(uint256 => uint256)) public userWithdrawnFund;

    event UserDeposit(address indexed user, uint indexed roundId, uint indexed amount);
    event UserWithdrawn(address indexed user, uint indexed roundId, uint indexed amount);
    event MigrateDone(uint256 indexed _roundId);


   
    modifier isValidRound(uint256 _roundId) {
        require(rounds[_roundId].startTime > 0, "Invalid-round");
        _;
    }

    receive() external payable {
        
    }


    constructor(address _oldBridge) public { 
        catalystBridgeV1 = _oldBridge;
    }
    function userDeposit(uint256 _roundId) isValidRound(_roundId) external payable whenNotPaused() nonReentrant() { 
        RoundInfo memory round = rounds[_roundId];
        require(msg.value >= round.minAmountETH, "Invalid-fund");
        require(round.startTime <= block.timestamp && block.timestamp <= (round.startTime + round.depositDuration),"Can-not-deposit");
        uint256 fund = msg.value;
        round.totalDepositFund = round.totalDepositFund + fund;
        rounds[_roundId] = round;
        userFund[msg.sender][_roundId] = userFund[msg.sender][_roundId] + fund;
        emit UserDeposit(msg.sender, _roundId, fund);
    }
    
    function userWithDrawn(uint256 _roundId) isValidRound(_roundId) whenNotPaused external nonReentrant() {
        RoundInfo memory round = rounds[_roundId];
        uint256 fundOfUser = userFund[msg.sender][_roundId];
        require(fundOfUser > 0, "Invalid fund");
        require((block.timestamp <= round.startTime + round.depositDuration &&  round.totalWithDrawnFund == 0) ||
                (block.timestamp >= (round.startTime + round.depositDuration + round.stakeDuration) && round.totalWithDrawnFund > 0), "Can-not-withdrawn-now");
        uint256 amountToWithdrawn;
        if (round.totalWithDrawnFund == 0) {
            amountToWithdrawn = fundOfUser;
            round.totalDepositFund = round.totalDepositFund - amountToWithdrawn;
            rounds[_roundId] = round;
        } else {
            amountToWithdrawn = fundOfUser * round.totalWithDrawnFund / round.totalDepositFund;
            userWithdrawnFund[msg.sender][_roundId] = amountToWithdrawn;
        }
        payable(msg.sender).sendValue(amountToWithdrawn);
        emit UserWithdrawn(msg.sender, _roundId, amountToWithdrawn);
        delete userFund[msg.sender][_roundId];
    }

    function adminCollectFund(uint256 _roundId) isValidRound(_roundId) external onlyOwner() whenNotPaused() {
        require((rounds[_roundId].startTime + rounds[_roundId].depositDuration) < block.timestamp, "Deposit-time-not-end-yet");
        RoundInfo memory round = rounds[_roundId];
        uint256 collectValue = round.totalDepositFund;
        payable(msg.sender).sendValue(collectValue);
    }

    function adminDepositFund(uint256 _roundId) isValidRound(_roundId) external payable onlyOwner() whenNotPaused() {
        RoundInfo memory round = rounds[_roundId];
        require((round.startTime + round.depositDuration + round.stakeDuration) < block.timestamp, "Round-not-end-yet");
        uint256 depositValue = msg.value;
        round.totalWithDrawnFund = depositValue;
        rounds[_roundId] = round;
    }

    function emergencyWithdawn() external onlyOwner() whenPaused() {
        payable(msg.sender).sendValue((address(this).balance));
    }

    function adminMigrateData(uint _roundId, address[] memory _userDepositList) external onlyOwner() {
         (uint256 _startTime,
        uint256 _minAmountETH,
        uint256 _depositDuration,
        uint256 _stakeDuration,
        uint256 _totalDepositFund,
        uint256 _totalWithDrawnFund) = CataLystBridgeV1(catalystBridgeV1).rounds(_roundId);
        RoundInfo memory newRound;
        newRound.startTime = _startTime;
        newRound.minAmountETH = _minAmountETH;
        newRound.depositDuration = _depositDuration;
        newRound.stakeDuration = _stakeDuration;
        newRound.totalDepositFund = _totalDepositFund;
        newRound.totalWithDrawnFund = _totalWithDrawnFund;
        rounds[_roundId] = newRound;
        totalRounds = totalRounds + 1;
        for(uint i = 0; i < _userDepositList.length; i++) {
            userFund[_userDepositList[i]][_roundId] = CataLystBridgeV1(catalystBridgeV1).userFund(_userDepositList[i], _roundId);
        }
        emit MigrateDone(_roundId);
    }
}
