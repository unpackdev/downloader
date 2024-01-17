// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IBullRun.sol";
import "./ITopia.sol";
import "./IHUB.sol";
import "./ICoinFlip.sol";

contract Bet is Ownable, ReentrancyGuard {

    IBullRun private BullRunInterface;
    ITopia private TopiaInterface;
    IHUB private HubInterface;
    ICoinFlip private CoinFlipInterface;
    
    address payable public RandomizerContract; // VRF contract to decide nft stealing
    address payable public dev;
    uint256 public currentEncierroId; // set to current one
    uint256 public maxDuration;
    uint256 public minDuration;
    uint256 public SEED_COST = 0.0002 ether;
    uint256 public DEV_FEE = .001 ether;

    uint16 public runnerMult = 175;
    uint16 public bullMult = 185;
    uint16 public matadorMult = 200;
    uint16 public alphaMult = 200;

    mapping(uint256 => Encierro) public Encierros; // mapping for Encierro id to unlock corresponding encierro params
    mapping(address => uint256[]) public EnteredEncierros; // list of Encierro ID's that a particular address has bet in
    // GENESIS
    mapping(address => mapping(uint256 => uint16[])) public BetNFTsPerEncierro; // keeps track of each players token IDs bet for each encierro
    mapping(uint16 => mapping(uint256 => NFTBet)) public BetNFTInfo; // tokenID to bet info (each staked NFT is its own separate bet) per session
    // ALPHAS
    mapping(address => mapping(uint256 => uint16[])) public BetAlphasPerEncierro; // keeps track of each players token IDs bet for each encierro
    mapping(uint16 => mapping(uint256 => NFTBet)) public BetAlphaInfo; // tokenID to bet info (each staked NFT is its own separate bet) per session
    // All
    mapping(address => mapping(uint256 => bool)) public HasBet; 
    mapping(address => mapping(uint256 => bool)) public HasClaimed;  

    uint16 public alphaCut = 1000;

    constructor(address _bullRun, address _topia, address _hub, address payable _randomizer, address _coinFlip) {
        BullRunInterface = IBullRun(_bullRun);
        TopiaInterface = ITopia(_topia);
        HubInterface = IHUB(_hub);
        CoinFlipInterface = ICoinFlip(_coinFlip);
        RandomizerContract = _randomizer;
        currentEncierroId = 1;
        dev = payable(msg.sender);
    }

    event BetRewardClaimed (address indexed claimer, uint256 amount);
    event BullsWin (uint80 timestamp, uint256 encierroID);
    event RunnersWin (uint80 timestamp, uint256 encierroID);
    event EncierroOpened(
        uint256 indexed encierroId,
        uint256 startTime,
        uint256 endTime,
        uint256 minBet,
        uint256 maxBet
    );

    event BetPlaced(
        address indexed player, 
        uint256 indexed encierroId, 
        uint256 amount,
        uint8 choice,
        uint16[] tokenIDs
    );

    event EncierroClosed(
        uint256 indexed encierroId, 
        uint256 endTime,
        uint16 numRunners,
        uint16 numBulls,
        uint16 numMatadors,
        uint16 numAlphas,
        uint16 numberOfBetsOnRunnersWinning,
        uint16 numberOfBetsOnBullsWinning,
        uint256 topiaBetByRunners, // all TOPIA bet by runners
        uint256 topiaBetByBulls, // all TOPIA bet by bulls
        uint256 topiaBetByMatadors, // all TOPIA bet by matadors
        uint256 topiaBetByAlphas, // all TOPIA bet by alphas
        uint256 topiaBetOnRunners, // all TOPIA bet that runners will win
        uint256 topiaBetOnBulls, // all TOPIA bet that bulls will win
        uint256 totalTopiaCollected
    );

    event CoinFlipped(
        uint256 flipResult,
        uint256 indexed encierroId
    );

    // an individual NFT being bet
    struct NFTBet {
        address player;
        uint256 amount; 
        uint8 choice; // (0) BULLS or (1) RUNNERS;
        uint16 tokenID;
        uint8 typeOfNFT;
    }

    enum Status {
        Closed,
        Open,
        Standby,
        Claimable
    }

    struct Encierro {
        Status status;
        uint256 encierroId; // increments monotonically 
        uint256 startTime; // unix timestamp
        uint256 endTime; // unix timestamp
        uint256 minBet;
        uint256 maxBet;
        uint16 numRunners; // number of runners entered
        uint16 numBulls; // number of bulls entered
        uint16 numMatadors; // number of matadors entered
        uint16 numAlphas; // number of alphas entered
        uint16 numberOfBetsOnRunnersWinning; // # of people betting for runners
        uint16 numberOfBetsOnBullsWinning; // # of people betting for bulls
        uint256 topiaBetByRunners; // all TOPIA bet by runners
        uint256 topiaBetByBulls; // all TOPIA bet by bulls
        uint256 topiaBetByMatadors; // all TOPIA bet by matadors
        uint256 topiaBetByAlphas; // all TOPIA bet by alphas
        uint256 topiaBetOnRunners; // all TOPIA bet that runners will win
        uint256 topiaBetOnBulls; // all TOPIA bet that bulls will win
        uint256 totalTopiaCollected; // total TOPIA collected from bets for the entire round
        uint256 flipResult; // 0 for bulls, 1 for runners
    }
    // ---- setters:

    function setHUB(address _hub) external onlyOwner {
        HubInterface = IHUB(_hub);
    }

    function setTopiaToken(address _topiaToken) external onlyOwner {
        TopiaInterface = ITopia(_topiaToken);
    }

    function setRNGContract(address _coinFlipContract) external onlyOwner {
        CoinFlipInterface = ICoinFlip(_coinFlipContract);
    }

    function setRandomizer(address _randomizer) external onlyOwner {
        RandomizerContract = payable(_randomizer);
    }

    function setSeedCost(uint256 _cost, uint256 _fee) external onlyOwner {
        SEED_COST = _cost;
        DEV_FEE = _fee;
    }

    function setBullRunContract(address _bullRun) external onlyOwner {
        BullRunInterface = IBullRun(_bullRun);
    }

    function setWinMultipliers(uint16 _runner, uint16 _bull, uint16 _matador, uint16 _alpha) external onlyOwner {
        runnerMult = _runner;
        bullMult = _bull;
        matadorMult = _matador;
        alphaMult = _alpha;
    }
    
    function setAlphaCut(uint16 _cut) external onlyOwner {
        alphaCut = _cut;
    }

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

    function getStakedNFTInfo(uint16 _tokenID) public returns (uint16, address, uint80, uint8, uint256) {
        uint16 tokenID;
        address owner;
        uint80 stakeTimestamp;
        uint8 typeOfNFT;
        uint256 value;
        (tokenID, owner, stakeTimestamp, typeOfNFT, value) = BullRunInterface.StakedNFTInfo(_tokenID);

        return (tokenID, owner, stakeTimestamp, typeOfNFT, value);
    }

    function getStakedAlphaInfo(uint16 _tokenID) public returns (uint16, address, uint80, uint8, uint256) {
        uint16 tokenID;
        address owner;
        uint80 stakeTimestamp;
        uint8 typeOfNFT;
        uint256 value;
        (tokenID, owner, stakeTimestamp, typeOfNFT, value) = BullRunInterface.StakedAlphaInfo(_tokenID);

        return (tokenID, owner, stakeTimestamp, typeOfNFT, value);
    }

    function setMinMaxDuration(uint256 _min, uint256 _max) external onlyOwner {
        minDuration = _min;
        maxDuration = _max;
    }

    function betMany(uint16[] calldata _tokenIds, uint256 _encierroId, uint256 _betAmount, uint8 _choice) external payable
    nonReentrant {
        require(msg.value == SEED_COST + DEV_FEE, "seed cost not met");
        require(Encierros[_encierroId].endTime > block.timestamp , "Betting has ended");
        require(TopiaInterface.balanceOf(address(msg.sender)) >= (_betAmount * _tokenIds.length), "not enough TOPIA");
        require(_choice == 1 || _choice == 0, "Invalid choice");
        require(Encierros[_encierroId].status == Status.Open, "not open");
        require(_betAmount >= Encierros[_encierroId].minBet && _betAmount <= Encierros[_encierroId].maxBet, "Bet not within limits");

        RandomizerContract.transfer(SEED_COST);
        dev.transfer(DEV_FEE);
        uint16 numberOfNFTs = uint16(_tokenIds.length);
        uint256 totalBet = _betAmount * numberOfNFTs;
        for (uint i = 0; i < numberOfNFTs;) {
            address tokenOwner;
            uint8 tokenType;
            (,tokenOwner,,tokenType,) = getStakedNFTInfo(_tokenIds[i]);
            require(tokenOwner == msg.sender, "not owner");

            if (tokenType == 1) {
                betRunner(_tokenIds[i], _encierroId, _betAmount, _choice);
            } else if (tokenType == 2) {
                betBull(_tokenIds[i], _encierroId, _betAmount, _choice);
            } else if (tokenType == 3) {
                betMatador(_tokenIds[i], _encierroId, _betAmount, _choice);
            } else if (tokenType == 0) {
                continue;
            }

            Encierros[_encierroId].totalTopiaCollected += totalBet;
            
            if (_choice == 0) {
                Encierros[_encierroId].numberOfBetsOnBullsWinning += numberOfNFTs; // increase the number of bets on bulls winning by # of NFTs being bet
                Encierros[_encierroId].topiaBetOnBulls += totalBet; // multiply the bet amount per NFT by the number of NFTs
            } else {
                Encierros[_encierroId].numberOfBetsOnRunnersWinning += numberOfNFTs; // increase number of bets on runners...
                Encierros[_encierroId].topiaBetOnRunners += totalBet;
            }

            if (!HasBet[msg.sender][_encierroId]) {
                HasBet[msg.sender][_encierroId] = true;
                EnteredEncierros[msg.sender].push(_encierroId);
            }
            HubInterface.burnFrom(msg.sender, totalBet);
            emit BetPlaced(msg.sender, _encierroId, totalBet, _choice, _tokenIds);
            unchecked{ i++; }
            }
    }

    function betManyAlphas(uint16[] calldata _tokenIds, uint256 _encierroId, uint256 _betAmount, uint8 _choice) external payable
    nonReentrant {
        require(msg.value == SEED_COST + DEV_FEE, "seed cost not met");
        require(Encierros[_encierroId].endTime > block.timestamp , "Betting has ended");
        require(TopiaInterface.balanceOf(address(msg.sender)) >= (_betAmount * _tokenIds.length), "not enough TOPIA");
        require(_choice == 1 || _choice == 0, "Invalid choice");
        require(Encierros[_encierroId].status == Status.Open, "not open");
        require(_betAmount >= Encierros[_encierroId].minBet && _betAmount <= Encierros[_encierroId].maxBet, "Bet not within limits");

        RandomizerContract.transfer(SEED_COST);
        dev.transfer(DEV_FEE);
        uint16 numberOfNFTs = uint16(_tokenIds.length);
        uint256 totalBet = _betAmount * numberOfNFTs;
        for (uint i = 0; i < numberOfNFTs;) {
            address tokenOwner;
            (,tokenOwner,,,) = getStakedAlphaInfo(_tokenIds[i]);
            require(tokenOwner == msg.sender, "not owner");

            betAlpha(_tokenIds[i], _encierroId, _betAmount, _choice);

            Encierros[_encierroId].totalTopiaCollected += totalBet;
            
            if (_choice == 0) {
                Encierros[_encierroId].numberOfBetsOnBullsWinning += numberOfNFTs; // increase the number of bets on bulls winning by # of NFTs being bet
                Encierros[_encierroId].topiaBetOnBulls += totalBet; // multiply the bet amount per NFT by the number of NFTs
            } else {
                Encierros[_encierroId].numberOfBetsOnRunnersWinning += numberOfNFTs; // increase number of bets on runners...
                Encierros[_encierroId].topiaBetOnRunners += totalBet;
            }

            if (!HasBet[msg.sender][_encierroId]) {
                HasBet[msg.sender][_encierroId] = true;
                EnteredEncierros[msg.sender].push(_encierroId);
            }
            HubInterface.burnFrom(msg.sender, totalBet);
            emit BetPlaced(msg.sender, _encierroId, totalBet, _choice, _tokenIds);
            unchecked{ i++; }
        }
    }

    function betRunner(uint16 _runnerID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_runnerID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_runnerID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_runnerID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_runnerID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_runnerID][_encierroId].tokenID = _runnerID; // map bet token id to struct id for this session
        BetNFTInfo[_runnerID][_encierroId].typeOfNFT = 1; // 1 = runner

        Encierros[_encierroId].topiaBetByRunners += _betAmount;
        Encierros[_encierroId].numRunners++;
    }

    function betBull(uint16 _bullID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_bullID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_bullID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_bullID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_bullID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_bullID][_encierroId].tokenID = _bullID; // map bet token id to struct id for this session
        BetNFTInfo[_bullID][_encierroId].typeOfNFT = 2; // 2 = bull

        Encierros[_encierroId].topiaBetByBulls += _betAmount;
        Encierros[_encierroId].numBulls++;
    }

    function betMatador(uint16 _matadorID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_matadorID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_matadorID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_matadorID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_matadorID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_matadorID][_encierroId].tokenID = _matadorID; // map bet token id to struct id for this session
        BetNFTInfo[_matadorID][_encierroId].typeOfNFT = 3; // 3 = matador

        Encierros[_encierroId].topiaBetByMatadors += _betAmount;
        Encierros[_encierroId].numMatadors++;
    }

    function betAlpha(uint16 _alphaID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {
        BetAlphasPerEncierro[msg.sender][_encierroId].push(_alphaID); // add the token IDs being bet to their personal mapping for this session
        BetAlphaInfo[_alphaID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetAlphaInfo[_alphaID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetAlphaInfo[_alphaID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetAlphaInfo[_alphaID][_encierroId].tokenID = _alphaID; // map bet token id to struct id for this session
        BetAlphaInfo[_alphaID][_encierroId].typeOfNFT = 0; // 0 = alpha

        Encierros[_encierroId].topiaBetByAlphas += _betAmount;
        Encierros[_encierroId].numAlphas++;
    }

    function claimManyBetRewards() external 
    nonReentrant notContract() {

        uint256 owed; // what caller collects for winning
        for(uint i = 0; i < EnteredEncierros[msg.sender].length;) {
            uint256 sessionID = EnteredEncierros[msg.sender][i];
            if(Encierros[sessionID].status == Status.Claimable && !HasClaimed[msg.sender][sessionID] && HasBet[msg.sender][sessionID]) {
                uint8 winningResult = uint8(Encierros[sessionID].flipResult);
                require(winningResult <= 1 , "Invalid flip result");
                for (uint16 z = 0; z < BetNFTsPerEncierro[msg.sender][sessionID].length;) { // fetch their bet NFT ids for this encierro                    
                    // calculate winnings
                    if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].choice == winningResult && 
                        BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].typeOfNFT == 1) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * runnerMult) / 100;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].typeOfNFT == 2) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * bullMult) / 100;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].typeOfNFT == 3) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * matadorMult) / 100;
                    } else {
                        continue;
                    }
                    unchecked{ z++; }
                }

                for (uint16 z = 0; z < BetAlphasPerEncierro[msg.sender][sessionID].length;) { // fetch their bet NFT ids for this encierro                    
                    // calculate winnings
                    if (BetAlphaInfo[BetAlphasPerEncierro[msg.sender][sessionID][z]][sessionID].choice == winningResult) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetAlphaInfo[BetAlphasPerEncierro[msg.sender][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * alphaMult) / 100;

                    } else {
                        continue;
                    }
                    unchecked{ z++; }
                }

                HasClaimed[msg.sender][sessionID] = true;
            } else {
                continue;
            }
            unchecked{ i++; }
        }

        HubInterface.pay(msg.sender, owed);
        emit BetRewardClaimed(msg.sender, owed);
    }

    // Encierro SESSION LOGIC ---------------------------------------------------- 

    function startEncierro(
        uint256 _endTime,
        uint256 _minBet,
        uint256 _maxBet) 
        external
        nonReentrant
        {
        require(
            (currentEncierroId == 1) || 
            (Encierros[currentEncierroId].status == Status.Claimable), "session not claimable");

        require(((_endTime - block.timestamp) >= minDuration) && ((_endTime - block.timestamp) <= maxDuration), "invalid time");

        currentEncierroId++;

        Encierros[currentEncierroId] = Encierro({
            status: Status.Open,
            encierroId: currentEncierroId,
            startTime: block.timestamp,
            endTime: _endTime,
            minBet: _minBet,
            maxBet: _maxBet,
            numRunners: 0,
            numBulls: 0,
            numMatadors: 0,
            numAlphas: 0,
            numberOfBetsOnRunnersWinning: 0,
            numberOfBetsOnBullsWinning: 0,
            topiaBetByRunners: 0,
            topiaBetByBulls: 0,
            topiaBetByMatadors: 0,
            topiaBetByAlphas: 0,
            topiaBetOnRunners: 0,
            topiaBetOnBulls: 0,
            totalTopiaCollected: 0,
            flipResult: 2 // init to 2 to avoid conflict with 0 (bulls) or 1 (runners). is set to 0 or 1 later depending on coin flip result.
        });
        
        emit EncierroOpened(
            currentEncierroId,
            block.timestamp,
            _endTime,
            _minBet,
            _maxBet
        );
    }

    // bulls = 0, runners = 1
    function closeEncierro(uint256 _encierroId) external nonReentrant {
        require(Encierros[_encierroId].status == Status.Open , "must be open first");
        require(block.timestamp > Encierros[_encierroId].endTime, "not over yet");
        CoinFlipInterface.requestRandomWords();
        Encierros[_encierroId].status = Status.Closed;
        emit EncierroClosed(
            _encierroId,
            block.timestamp,
            Encierros[_encierroId].numRunners,
            Encierros[_encierroId].numBulls,
            Encierros[_encierroId].numMatadors,
            Encierros[_encierroId].numAlphas,
            Encierros[_encierroId].numberOfBetsOnRunnersWinning,
            Encierros[_encierroId].numberOfBetsOnBullsWinning,
            Encierros[_encierroId].topiaBetByRunners,
            Encierros[_encierroId].topiaBetByBulls,
            Encierros[_encierroId].topiaBetByMatadors,
            Encierros[_encierroId].topiaBetByAlphas,
            Encierros[_encierroId].topiaBetOnRunners,
            Encierros[_encierroId].topiaBetOnBulls,
            Encierros[_encierroId].totalTopiaCollected
        );
    }

    function flipCoinAndMakeClaimable(uint256 _encierroId) external nonReentrant notContract() returns (uint256) {
        require(_encierroId <= currentEncierroId , "Nonexistent session!");
        require(Encierros[_encierroId].status == Status.Closed , "must be closed first");
        uint256 encierroFlipResult = _flipCoin();
        Encierros[_encierroId].flipResult = encierroFlipResult;

        if (encierroFlipResult == 0) { // if bulls win
            uint256 amountToAlphas = (Encierros[_encierroId].topiaBetOnRunners * alphaCut) / 10000;
            BullRunInterface.payAlphaTax(amountToAlphas);
        } else { // if runners win
            uint256 amountToAlphas = (Encierros[_encierroId].topiaBetOnBulls * alphaCut) / 10000;
            BullRunInterface.payAlphaTax(amountToAlphas);
        }

        Encierros[_encierroId].status = Status.Claimable;
        return encierroFlipResult;
    }

    function _flipCoin() internal returns (uint256) {
        uint256 result = CoinFlipInterface.oneOutOfTwo();
        Encierros[currentEncierroId].status = Status.Standby;
        if (result == 0) {
            Encierros[currentEncierroId].flipResult = 0;
            emit BullsWin(uint80(block.timestamp), currentEncierroId);
        } else {
            Encierros[currentEncierroId].flipResult = 1;
            emit RunnersWin(uint80(block.timestamp), currentEncierroId);
        }
        emit CoinFlipped(result, currentEncierroId);
        return result;
    }

    function viewEncierroById(uint256 _encierroId) external view returns (Encierro memory) {
        return Encierros[_encierroId];
    }

    function getEnteredEncierrosLength(address _better) external view returns (uint256) {
        return EnteredEncierros[_better].length;
    }

    function getUserNFTsPerEncierro(address account, uint256 _id) external view returns (uint16[] memory tokenIds) {
        uint256 length = BetNFTsPerEncierro[account][_id].length;
        tokenIds = new uint16[](length);
        for(uint i = 0; i < length;) {
            tokenIds[i] = BetNFTsPerEncierro[account][_id][i];
            unchecked{ i++; }
        }
    }

    function getUnclaimedBetRewards(address account) external view returns (uint256){
        uint256 owed; // what caller collects for winning
        for(uint i = 0; i < EnteredEncierros[account].length;) {
            uint256 sessionID = EnteredEncierros[account][i];
            if(Encierros[sessionID].status == Status.Claimable && !HasClaimed[account][sessionID] && HasBet[account][sessionID]) {
                uint8 winningResult = uint8(Encierros[sessionID].flipResult);
                require(winningResult <= 1 , "Invalid flip result");
                for (uint16 z = 0; z < BetNFTsPerEncierro[account][sessionID].length;) { // fetch their bet NFT ids for this encierro                    
                    // calculate winnings
                    if (BetNFTInfo[BetNFTsPerEncierro[account][sessionID][z]][sessionID].choice == winningResult && 
                        BetNFTInfo[BetNFTsPerEncierro[account][sessionID][z]][sessionID].typeOfNFT == 1) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[account][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * runnerMult) / 100;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[account][sessionID][z]][sessionID].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[account][sessionID][z]][sessionID].typeOfNFT == 2) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[account][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * bullMult) / 100;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[account][sessionID][z]][sessionID].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[account][sessionID][z]][sessionID].typeOfNFT == 3) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[account][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * matadorMult) / 100;
                    } else {
                        continue;
                    }
                    unchecked{ z++; }
                }

                for (uint16 z = 0; z < BetAlphasPerEncierro[account][sessionID].length;) { // fetch their bet NFT ids for this encierro                    
                    // calculate winnings
                    if (BetAlphaInfo[BetAlphasPerEncierro[account][sessionID][z]][sessionID].choice == winningResult) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetAlphaInfo[BetAlphasPerEncierro[account][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * alphaMult) / 100;

                    } else {
                        continue;
                    }
                    unchecked{ z++; }
                }

            } else {
                continue;
            }
            unchecked{ i++; }
        }
        return owed;
    }
}