// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

contract DuelBettingContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    enum MatchOutcome { NOT_FINISHED, A, B }

    event NewMatchStarted();
    event BetPlaced(address indexed bettor, MatchOutcome outcome, uint256 amount);
    event OutcomeDeclared(MatchOutcome outcome);
    event WinningsDistributed(MatchOutcome winningOutcome);
    event AdminFeesWithdrawn(uint256 amount);

    struct Match {
        uint256 betA;
        uint256 betB;
        MatchOutcome outcome;
        mapping(address => uint256) betsA;
        mapping(address => uint256) betsB;
        address[] bettorsA;
        address[] bettorsB;
    }

    Match currentMatch;
    bool public matchActive = false;
    uint256 public minBetAmount = 10000000000000000; // 0.01e
    uint256 public maxBetAmount = 100000000000000000; // 0.1e
    uint256 public adminFeePercentage = 5;
    uint256 public playerLimit = 25;
    uint256 public accumulatedFees;
    MatchOutcome previousOutcome;

    mapping(address => uint256) lastParticipatedMatch;
    uint256 public currentMatchNonce = 0;

    function startNewMatch() external onlyOwner {
        require(!matchActive, "Finish the current match first");
        
        // bad code but scalable on l2 if required
        for (uint i = 0; i < currentMatch.bettorsA.length; i++) {
            delete currentMatch.betsA[currentMatch.bettorsA[i]];
            delete currentMatch.bettorsA[i];
        }
        for (uint i = 0; i < currentMatch.bettorsB.length; i++) {
            delete currentMatch.betsB[currentMatch.bettorsB[i]];
            delete currentMatch.bettorsB[i];
        }

        currentMatch.betA = 0;
        currentMatch.betB = 0;
        currentMatch.outcome = MatchOutcome.NOT_FINISHED;
        currentMatch.bettorsA = new address[](0);
        currentMatch.bettorsB = new address[](0);
        
        matchActive = true;
        currentMatchNonce = currentMatchNonce.add(1);

        emit NewMatchStarted();
    }

    function _recordBettor(address[] storage bettors, address bettor) private {
        if (lastParticipatedMatch[bettor] < currentMatchNonce) {
            bettors.push(bettor);
            lastParticipatedMatch[bettor] = currentMatchNonce;
        } else if (lastParticipatedMatch[bettor] == currentMatchNonce) {
            revert("You can only bet once per match.");
        }
    }

    function _isContract(address addr) private view returns(bool) {
        uint32 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function _betOnOutcome(MatchOutcome outcome, uint256 amount) private {
        require(!_isContract(msg.sender), "Contracts are not allowed to bet");
        require(matchActive, "No active match");
        require(amount >= minBetAmount && amount <= maxBetAmount, "Invalid bet amount");
        require(msg.value == amount, "Mismatched ether sent");

        if (outcome == MatchOutcome.A) {
            require(currentMatch.bettorsA.length < playerLimit, "Player limit reached for Outcome A");
            _recordBettor(currentMatch.bettorsA, msg.sender);
            currentMatch.betA = currentMatch.betA.add(amount);
            currentMatch.betsA[msg.sender] = currentMatch.betsA[msg.sender].add(amount);
        } else if (outcome == MatchOutcome.B) {
            require(currentMatch.bettorsB.length < playerLimit, "Player limit reached for Outcome B");
            _recordBettor(currentMatch.bettorsB, msg.sender);
            currentMatch.betB = currentMatch.betB.add(amount);
            currentMatch.betsB[msg.sender] = currentMatch.betsB[msg.sender].add(amount);
        }

        emit BetPlaced(msg.sender, outcome, amount);
    }

    function betOnOutcomeA(uint256 amount) external payable {
        _betOnOutcome(MatchOutcome.A, amount);
    }

    function betOnOutcomeB(uint256 amount) external payable {
        _betOnOutcome(MatchOutcome.B, amount);
    }

    function declareOutcome(MatchOutcome outcome) external onlyOwner {
        require(matchActive, "No active match");
        require(outcome != MatchOutcome.NOT_FINISHED, "Invalid outcome");
        require(currentMatch.bettorsA.length > 0, "No bets on Outcome A.");
        require(currentMatch.bettorsB.length > 0, "No bets on Outcome B.");
        
        currentMatch.outcome = outcome;
        previousOutcome = outcome;
        
        matchActive = false;

        emit OutcomeDeclared(outcome);
    }

    function distributeWinnings() external onlyOwner nonReentrant {
        require(!matchActive, "Match is still active");
        require(currentMatch.outcome != MatchOutcome.NOT_FINISHED, "Match hasn't finished yet");

        if (currentMatch.outcome == MatchOutcome.A) {
            uint256 adminFee = currentMatch.betB.mul(adminFeePercentage).div(100);
            accumulatedFees = accumulatedFees.add(adminFee);

            uint256 payoutPool = currentMatch.betB.sub(adminFee);
            for (uint i = 0; i < currentMatch.bettorsA.length; i++) {
                address bettor = currentMatch.bettorsA[i];
                uint256 initialBet = currentMatch.betsA[bettor];
                uint256 reward = payoutPool.mul(initialBet).div(currentMatch.betA).add(initialBet); // Added initial bet
                currentMatch.betsA[bettor] = 0; // Prevent re-entrancy
                payable(bettor).transfer(reward);
            }
        } else if (currentMatch.outcome == MatchOutcome.B) {
            uint256 adminFee = currentMatch.betA.mul(adminFeePercentage).div(100);
            accumulatedFees = accumulatedFees.add(adminFee);

            uint256 payoutPool = currentMatch.betA.sub(adminFee);
            for (uint i = 0; i < currentMatch.bettorsB.length; i++) {
                address bettor = currentMatch.bettorsB[i];
                uint256 initialBet = currentMatch.betsB[bettor];
                uint256 reward = payoutPool.mul(initialBet).div(currentMatch.betB).add(initialBet); // Added initial bet
                currentMatch.betsB[bettor] = 0; // Prevent re-entrancy
                payable(bettor).transfer(reward);
            }
        }

        emit WinningsDistributed(currentMatch.outcome);
    }

    function withdrawAccumulatedFees() external onlyOwner {
        require(accumulatedFees > 0, "No fees to withdraw");

        uint256 amount = accumulatedFees;
        accumulatedFees = 0;
        payable(owner()).transfer(amount);

        emit AdminFeesWithdrawn(amount);
    }

    function setLimits(uint256 _minBetAmount, uint256 _maxBetAmount, uint256 _playerLimit) external onlyOwner {
        require(_minBetAmount < _maxBetAmount, "Invalid bet limits");
        require(!matchActive, "Finish the current match first");
        minBetAmount = _minBetAmount;
        maxBetAmount = _maxBetAmount;
        playerLimit = _playerLimit;
    }

    function setAdminFeePercentage(uint256 _adminFeePercentage) external onlyOwner {
        require(_adminFeePercentage < 100, "Fee percentage too high");
        adminFeePercentage = _adminFeePercentage;
    }

    function getNumberOfBettors() external view returns (uint256 numBettorsA, uint256 numBettorsB) {
        numBettorsA = currentMatch.bettorsA.length;
        numBettorsB = currentMatch.bettorsB.length;
    }

    function getMatchBetAmount() external view returns (uint256 betAmountA, uint256 betAmountB) {
        betAmountA = currentMatch.betA;
        betAmountB = currentMatch.betB;
    }
}