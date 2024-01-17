// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IRandomizer.sol";
import "./ITOPIA.sol";
import "./IHUB.sol";


contract ClawMachineGame is Ownable, ReentrancyGuard {

    IRandomizer public randomizer;
    IHUB private HUB;
    address payable vrf;
    address payable dev;

    ITopia private TopiaInterface = ITopia(0x649E1135b1232b68468A354f36DBfcE32813D49a);

    uint256 public SEED_COST = .0008 ether;
    uint256 public DEV_FEE = .001 ether;
    uint256 public COST_TO_PLAY = 20 * 10**18;
    uint256 public totalPayouts; // lifetime total of TOPIA paid out to winners
    uint256 public totalAmountBet; // lifetime total of TOPIA bet
    uint16 public numLosses; // lifetime total losses
    uint16 public numBets; // lifetime total plays
    uint16 public numFishBones; // lifetime total fish bones won
    uint16 public numMice; // lifetime total mice won
    uint16 public numTennisBalls; // lifetime total tennis balls won
    uint16 public numGoldenBones; // lifetime total golden bones won
    uint16 public numTopiaStones; // lifetime total topia stones won

    constructor(address _rand, address _HUB) { 
        randomizer = IRandomizer(_rand);
        HUB = IHUB(_HUB);
        vrf = payable(_rand);
        dev = payable(msg.sender);
    }

    receive() external payable {}

    event ClawMachineBetPlaced(address indexed player, uint256 bet);
    event NoPrize(address indexed loser, uint256 timeStamp);
    event WonFishBone(address indexed winner, uint256 timeStamp);
    event WonMouse(address indexed winner, uint256 timeStamp);
    event WonTennisBall(address indexed winner, uint256 timeStamp);
    event WonGoldenBone(address indexed winner, uint256 timeStamp);
    event WonTopiaStone(address indexed winner, uint256 timeStamp);
    event WinnerPaid(address indexed winner, uint256 payout);

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function updateDevCost(uint256 _cost) external onlyOwner {
        DEV_FEE = _cost;
    }

    function updateDev(address payable _dev) external onlyOwner {
        dev = _dev;
    }

    function setSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function setCostToPlay(uint256 _cost) external onlyOwner {
        COST_TO_PLAY = _cost;
    }

    function setHub(IHUB _hub) external onlyOwner {
        HUB = _hub;
    }

    function play() external payable nonReentrant notContract() returns (uint256 payout) {
        require(msg.value == SEED_COST + DEV_FEE, "invalid eth amount");
        require(randomizer.getRemainingWords() >= 1, "Not enough random numbers. Please try again soon.");
        HUB.burnFrom(msg.sender, COST_TO_PLAY);
        vrf.transfer(SEED_COST);
        dev.transfer(DEV_FEE);
        numBets++;
        totalAmountBet += COST_TO_PLAY;
        emit ClawMachineBetPlaced(msg.sender, COST_TO_PLAY);

        uint256[] memory seed = randomizer.getRandomWords(1);
        uint8 randNum = uint8(seed[0] % 100);

        if (randNum >= 0 && randNum < 15) {
            payout = 0;
            numLosses++;
            emit NoPrize(msg.sender, block.timestamp);
        } else if (randNum >= 15 && randNum < 25) {
            payout = 10 * 10**18;
            numFishBones++;
            emit WonFishBone(msg.sender, block.timestamp);
        } else if (randNum >= 25 && randNum < 60) {
            payout = 20 * 10**18;
            numMice++;
            emit WonMouse(msg.sender, block.timestamp);
        } else if (randNum >= 60 && randNum < 80) {
            payout = 40 * 10**18;
            numTennisBalls++;
            emit WonTennisBall(msg.sender, block.timestamp);
        } else if (randNum >= 80 && randNum < 95) {
            payout = 80 * 10**18;
            numGoldenBones++;
            emit WonGoldenBone(msg.sender, block.timestamp);
        } else if (randNum >= 95 && randNum <= 100) {
            payout = 250 * 10**18;
            numTopiaStones++;
            emit WonTopiaStone(msg.sender, block.timestamp);
        }
        if (payout > 0) {
            HUB.pay(msg.sender, payout);
            totalPayouts += payout;
            emit WinnerPaid(msg.sender, payout);
        } 
    }
}