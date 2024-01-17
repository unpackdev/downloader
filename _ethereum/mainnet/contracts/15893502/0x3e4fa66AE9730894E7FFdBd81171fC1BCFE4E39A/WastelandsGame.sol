// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ITopia.sol";
import "./IGenesis.sol";
import "./IHUB.sol";
import "./IRandomizer.sol";

contract WastelandsGame is Ownable, ReentrancyGuard {

    IGenesis private GenesisInterface;
    IRandomizer public randomizer;
    IHUB private HUB;
    address payable vrf;
    address payable dev;
    
    IERC721 private Wastelands = IERC721(0xB710a21680dCB32f6D4661Bcc015de8c13767559);
    IERC721 private Genesis = IERC721(0x97A792aCE504c2590C5046A7768A91CAd8aa0971);
    IERC721 public Alpha = IERC721(0xdf4F2DA93C07d590E16D34d2c19d3Ba93CB13E98); 
    ITopia private TopiaInterface = ITopia(0x649E1135b1232b68468A354f36DBfcE32813D49a);

    uint256 public totalTOPIAEarned;
    uint256 public DAILY_RAT_RATE;
    uint256 public DAILY_ALPHA_RATE;
    uint256 private PERIOD = 1 days;
    uint256 public SEED_COST = .0005 ether;
    uint256 public DEV_FEE = .0018 ether;

    uint16 private totalRatsStaked;
    uint16 private totalAlphasStaked;
    uint80 public claimEndTime = 1669662000;

    mapping(uint16 => Stake) private RatStake;
    mapping(address => uint16) public NumberOfStakedRats; // the number of NFTs a wallet has staked;

    mapping(uint16 => AStake) private AlphaStake;
    mapping(address => uint16) public NumberOfStakedAlphas;

    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint80 stakedAt;
    }

    struct AStake {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint80 stakedAt;
    }

    constructor(address _rand, address _HUB) { 
        randomizer = IRandomizer(_rand);
        HUB = IHUB(_HUB);
        vrf = payable(_rand);
        DAILY_RAT_RATE = 5 ether;
        DAILY_ALPHA_RATE = 10 ether;
        dev = payable(msg.sender);
    }

    event BetPlaced (
        address indexed player, uint256 bet,
        uint8 door1Choice, uint8 door2Choice, uint8 door3Choice, uint8 door4Choice,
        uint256 door1Correct, uint256 door2Correct, uint256 door3Correct, uint256 door4Correct
        );
    event NoDoorsCorrect (address indexed player, uint80 timestamp, uint256 bet);
    event OneDoorCorrect (address indexed player, uint80 timestamp, uint256 bet);
    event TwoDoorsCorrect (address indexed player, uint80 timestamp, uint256 bet);
    event ThreeDoorsCorrect (address indexed player, uint80 timestamp, uint256 bet);
    event FourDoorsCorrect (address indexed player, uint80 timestamp, uint256 bet);
    event WinnerPaid (address indexed player, uint256 payout);

    receive() external payable {}

    function setSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function closeSeasonEearnings(uint80 _timestamp) external onlyOwner {
        claimEndTime = _timestamp;
    }

    function updateDevCost(uint256 _cost) external onlyOwner {
        DEV_FEE = _cost;
    }

    function updateDev(address payable _dev) external onlyOwner {
        dev = _dev;
    }

    // INTERNAL FUNCTIONS *****************

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

    // CRITICAL TO SETUP ******************

    function setContracts(address _HUB, address payable _rand) external onlyOwner {
        randomizer = IRandomizer(_rand);
        HUB = IHUB(_HUB);
        vrf = _rand;
    }

    function setPayouts(uint256 _ratRate, uint256 _alphaRate) external onlyOwner {
        DAILY_RAT_RATE = _ratRate;
        DAILY_ALPHA_RATE = _alphaRate;
    }

    // STAKING AND CLAIMING FOR ALPHAS *******************

    function stakeAlpha(uint16[] calldata _ids) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "invalid eth amount");
        uint16 length = uint16(_ids.length);

        for (uint i = 0; i < length;) {
            require(Alpha.ownerOf(_ids[i]) == msg.sender , "not owner");
            HUB.receiveAlpha(msg.sender, _ids[i], 5);
            AlphaStake[_ids[i]] = AStake({
                owner : msg.sender,
                tokenId : _ids[i],
                value : uint80(block.timestamp),
                stakedAt : uint80(block.timestamp)
            });
            unchecked { i++; }
        }
        NumberOfStakedAlphas[msg.sender] += length;
        totalAlphasStaked += length;
        dev.transfer(DEV_FEE);
    }

    function claimAlphas(uint16[] calldata _ids, bool unstake) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "invalid eth amount");
        uint16 length = uint16(_ids.length);
        uint256 owed = 0;

        for (uint i = 0; i < length;) {
            require(AlphaStake[_ids[i]].owner == msg.sender , "not owner");

            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - AlphaStake[_ids[i]].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (AlphaStake[_ids[i]].value < claimEndTime) {
                owed += (claimEndTime - AlphaStake[_ids[i]].value) * DAILY_ALPHA_RATE / PERIOD;
            } else {
                owed += 0;
            }

            if (unstake) {
                delete AlphaStake[_ids[i]];
                HUB.returnAlphaToOwner(msg.sender, _ids[i], 5);
            }
            AlphaStake[_ids[i]].value = uint16(block.timestamp); // reset value
            unchecked { i++; }
        }
        if (unstake) {
            NumberOfStakedAlphas[msg.sender] -= length;
            totalAlphasStaked -= length;
        }
        totalTOPIAEarned += owed;
        if (owed > 0) {HUB.pay(msg.sender, owed);}
        dev.transfer(DEV_FEE);
    }

    function getTopiaPerAlpha(uint16 _id) external view returns (uint256 owed) {
        owed = 0;

        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - AlphaStake[_id].value) * DAILY_ALPHA_RATE / PERIOD;
        } else if (AlphaStake[_id].value < claimEndTime) {
            owed = (claimEndTime - AlphaStake[_id].value) * DAILY_ALPHA_RATE / PERIOD;
        } else {
            owed = 0;
        }

        return owed;
    }

    // STAKING AND CLAIMING FOR RATS *******************

    function stakeRat(uint16[] calldata _ids) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "invalid eth amount");
        uint16 length = uint16(_ids.length);

        for (uint i = 0; i < length;) {
            require(Wastelands.ownerOf(_ids[i]) == msg.sender , "not owner");
            HUB.receiveRat(msg.sender, _ids[i]);
            RatStake[_ids[i]] = Stake({
                owner : msg.sender,
                tokenId : _ids[i],
                value : uint80(block.timestamp),
                stakedAt : uint80(block.timestamp)
            });
            unchecked { i++; }
        }
        NumberOfStakedRats[msg.sender] += length;
        totalRatsStaked += length;
        dev.transfer(DEV_FEE);
    }

    function claimRats(uint16[] calldata _ids, bool unstake) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "invalid eth amount");
        uint16 length = uint16(_ids.length);
        uint256 owed = 0;

        for (uint i = 0; i < length;) {
            require(RatStake[_ids[i]].owner == msg.sender , "not owner");

            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - RatStake[_ids[i]].value) * DAILY_RAT_RATE / PERIOD;
            } else if (RatStake[_ids[i]].value < claimEndTime) {
                owed += (claimEndTime - RatStake[_ids[i]].value) * DAILY_RAT_RATE / PERIOD;
            } else {
                owed += 0;
            }

            if (unstake) {
                delete RatStake[_ids[i]];
                HUB.returnRatToOwner(msg.sender, _ids[i]);
            }
            RatStake[_ids[i]].value = uint16(block.timestamp); // reset value
            unchecked { i++; }
        }
        if (unstake) {
            NumberOfStakedRats[msg.sender] -= length;
            totalRatsStaked -= length;
        }
        
        if (owed > 0) {HUB.pay(msg.sender, owed);
        totalTOPIAEarned += owed;}
        dev.transfer(msg.value);
    }

    function getTopiaPerRat(uint16 _id) external view returns (uint256 owed) {
        owed = 0;

        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - RatStake[_id].value) * DAILY_RAT_RATE / PERIOD;
        } else if (RatStake[_id].value < claimEndTime) {
            owed = (claimEndTime - RatStake[_id].value) * DAILY_RAT_RATE / PERIOD;
        } else {
            owed = 0;
        }

        return owed;
    }

    // BETTING *******************

    function enterTheLabyrinth(uint8 _door1, uint8 _door2, uint8 _door3, uint8 _door4, uint256 _bet) external payable nonReentrant notContract() {
        require(_door1 <= 2 && _door2 <= 2 && _door3 <= 2 && _door4 <= 2 , "door options must be 0, 1, or 2");
        require(msg.value == SEED_COST + DEV_FEE, "invalid eth amount");
        require(NumberOfStakedRats[msg.sender] > 0 || NumberOfStakedAlphas[msg.sender] > 0, "must stake a rat or alpha to play");
        require(randomizer.getRemainingWords() >= 1, "Not enough random numbers. Please try again soon.");
        HUB.burnFrom(msg.sender, _bet);
        vrf.transfer(SEED_COST);
        dev.transfer(DEV_FEE);

        uint256[] memory seed = randomizer.getRandomWords(1);
        uint256 hash1 = seed[0] % 3;
        uint256 hash2 = (seed[0] >> 8) % 3;
        uint256 hash3 = (seed[0] >> 16) % 3;
        uint256 hash4 = (seed[0] >> 24) % 3;
        uint256 payout;

        if (_door1 != hash1) {
            payout = 0;
            emit NoDoorsCorrect(msg.sender, uint80(block.timestamp), _bet);
        } else if (_door1 == hash1 && _door2 != hash2) {
            payout = _bet / 2;
            emit OneDoorCorrect(msg.sender, uint80(block.timestamp), _bet);
        } else if (_door1 == hash1 && _door2 == hash2 && _door3 != hash3) {
            payout = _bet;
            emit TwoDoorsCorrect(msg.sender, uint80(block.timestamp), _bet);
        } else if (_door1 == hash1 && _door2 == hash2 && _door3 == hash3 && _door4 != hash4) {
            payout = _bet + (_bet / 2);
            emit ThreeDoorsCorrect(msg.sender, uint80(block.timestamp), _bet);
        } else if (_door1 == hash1 && _door2 == hash2 && _door3 == hash3 && _door4 == hash4) {
            payout = _bet * 10;
            emit FourDoorsCorrect(msg.sender, uint80(block.timestamp), _bet);
        }

        emit BetPlaced(
            msg.sender, _bet,
            _door1, _door2, _door3, _door4,
            hash1, hash2, hash3, hash4
        );

        if (payout > 0) {
            HUB.pay(msg.sender, payout);
            emit WinnerPaid(msg.sender, payout);
        }
    }
}