// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IBullRun.sol";
import "./ITopia.sol";
import "./IHub.sol";
import "./IMetatopiaCoinFlipRNG.sol";
import "./IArena.sol";

contract Bet is Ownable, ReentrancyGuard {

    IBullRun private BullRunInterface;
    ITopia private TopiaInterface;
    IHub private HubInterface;
    IMetatopiaCoinFlipRNG private MetatopiaCoinFlipRNGInterface;
    IArena private ArenaInterface;

    address payable public RandomizerContract; // VRF contract to decide nft stealing
    uint256 public currentEncierroId; // set to current one
    uint256 public maxDuration;
    uint256 public minDuration;
    uint256 public SEED_COST = 0.0001 ether;

    mapping(uint256 => Encierro) public Encierros; // mapping for Encierro id to unlock corresponding encierro params
    mapping(address => uint256[]) public EnteredEncierros; // list of Encierro ID's that a particular address has bet in
    mapping(address => mapping(uint256 => uint16[])) public BetNFTsPerEncierro; // keeps track of each players token IDs bet for each encierro
    mapping(uint16 => mapping(uint256 => NFTBet)) public BetNFTInfo; // tokenID to bet info (each staked NFT is its own separate bet) per session
    mapping(address => mapping(uint256 => bool)) public HasBet; 
    mapping(address => mapping(uint256 => bool)) public HasClaimed; 

    struct MatadorEarnings {
        uint256 owed;
        uint256 claimed;
    }
    mapping(uint16 => MatadorEarnings) public matadorEarnings;
    uint16[14] public matadorIds;
    uint256 public matadorCut = 500;

    constructor(address _bullRun, address _topia, address _hub, address payable _randomizer, address _coinFlip, address _arena) {
        BullRunInterface = IBullRun(_bullRun);
        TopiaInterface = ITopia(_topia);
        HubInterface = IHub(_hub);
        MetatopiaCoinFlipRNGInterface = IMetatopiaCoinFlipRNG(_coinFlip);
        ArenaInterface = IArena(_arena);
        RandomizerContract = _randomizer;
        currentEncierroId = 10;
        matadorIds = [34,425,1016,1097,1300,1329,1394,1855,1986,2049,2889,3074,3227,3299];
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
        uint16 numberOfBetsOnRunnersWinning,
        uint16 numberOfBetsOnBullsWinning,
        uint256 topiaBetByRunners, // all TOPIA bet by runners
        uint256 topiaBetByBulls, // all TOPIA bet by bulls
        uint256 topiaBetByMatadors, // all TOPIA bet by matadors
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
        uint16 numberOfBetsOnRunnersWinning; // # of people betting for runners
        uint16 numberOfBetsOnBullsWinning; // # of people betting for bulls
        uint256 topiaBetByRunners; // all TOPIA bet by runners
        uint256 topiaBetByBulls; // all TOPIA bet by bulls
        uint256 topiaBetByMatadors; // all TOPIA bet by matadors
        uint256 topiaBetOnRunners; // all TOPIA bet that runners will win
        uint256 topiaBetOnBulls; // all TOPIA bet that bulls will win
        uint256 totalTopiaCollected; // total TOPIA collected from bets for the entire round
        uint256 flipResult; // 0 for bulls, 1 for runners
    }
    // ---- setters:

    function setHUB(address _hub) external onlyOwner {
        HubInterface = IHub(_hub);
    }

    function setTopiaToken(address _topiaToken) external onlyOwner {
        TopiaInterface = ITopia(_topiaToken);
    }

    function setRNGContract(address _coinFlipContract) external onlyOwner {
        MetatopiaCoinFlipRNGInterface = IMetatopiaCoinFlipRNG(_coinFlipContract);
    }

    function setArenaContract(address _arena) external onlyOwner {
        ArenaInterface = IArena(_arena);
    }

    function setRandomizer(address _randomizer) external onlyOwner {
        RandomizerContract = payable(_randomizer);
    }

    function setSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }
    
    function setMatadorCut(uint256 _cut) external onlyOwner {
        matadorCut = _cut;
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

    function setMinMaxDuration(uint256 _min, uint256 _max) external onlyOwner {
        minDuration = _min;
        maxDuration = _max;
    }

    function betMany(uint16[] calldata _tokenIds, uint256 _encierroId, uint256 _betAmount, uint8 _choice) external 
    nonReentrant {
        require(Encierros[_encierroId].endTime > block.timestamp , "Betting has ended");
        require(_encierroId <= currentEncierroId, "Non-existent encierro id!");
        require(TopiaInterface.balanceOf(address(msg.sender)) >= (_betAmount * _tokenIds.length), "not enough TOPIA");
        require(_choice == 1 || _choice == 0, "Invalid choice");
        require(Encierros[_encierroId].status == Status.Open, "not open");
        require(_betAmount >= Encierros[_encierroId].minBet && _betAmount <= Encierros[_encierroId].maxBet, "Bet not within limits");

        uint16 numberOfNFTs = uint16(_tokenIds.length);
        uint256 totalBet = _betAmount * numberOfNFTs;
        for (uint i = 0; i < numberOfNFTs; i++) {
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
        TopiaInterface.burnFrom(msg.sender, totalBet);
        emit BetPlaced(msg.sender, _encierroId, totalBet, _choice, _tokenIds);
        }
    }

    function betRunner(uint16 _runnerID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {
        address tokenOwner;
        (,tokenOwner,,,) = getStakedNFTInfo(_runnerID);
        require(tokenOwner == msg.sender , "not owner");
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
        address tokenOwner;
        (,tokenOwner,,,) = getStakedNFTInfo(_bullID);
        require(tokenOwner == msg.sender , "not owner");
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
        address tokenOwner;
        (,tokenOwner,,,) = getStakedNFTInfo(_matadorID);
        require(tokenOwner == msg.sender , "not owner");
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_matadorID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_matadorID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_matadorID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_matadorID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_matadorID][_encierroId].tokenID = _matadorID; // map bet token id to struct id for this session
        BetNFTInfo[_matadorID][_encierroId].typeOfNFT = 3; // 3 = matador

        Encierros[_encierroId].topiaBetByMatadors += _betAmount;
        Encierros[_encierroId].numMatadors++;
    }

    function claimManyBetRewards() external 
    nonReentrant notContract() {

        uint256 owed; // what caller collects for winning
        for(uint i = 0; i < EnteredEncierros[msg.sender].length; i++) {
            uint256 sessionID = EnteredEncierros[msg.sender][i];
            if(Encierros[sessionID].status == Status.Claimable && !HasClaimed[msg.sender][sessionID] && HasBet[msg.sender][sessionID]) {
                uint8 winningResult = uint8(Encierros[sessionID].flipResult);
                require(winningResult <= 1 , "Invalid flip result");
                for (uint16 z = 0; z < BetNFTsPerEncierro[msg.sender][sessionID].length; z++) { // fetch their bet NFT ids for this encierro                    
                    // calculate winnings
                    if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].choice == winningResult && 
                        BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].typeOfNFT == 1) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * 5) / 4;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].typeOfNFT == 2) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * 3) / 2;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].typeOfNFT == 3) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][sessionID][z]][sessionID].amount;
                            owed += (topiaBetOnThisNFT * 2);
                    } else {
                        continue;
                    }
                }
                HasClaimed[msg.sender][sessionID] = true;
            } else {
                continue;
            }
        }

        TopiaInterface.mint(msg.sender, owed);
        HubInterface.emitTopiaClaimed(msg.sender, owed);
        emit BetRewardClaimed(msg.sender, owed);
    }

    // Encierro SESSION LOGIC ---------------------------------------------------- 

    function startEncierro(
        uint256 _endTime,
        uint256 _minBet,
        uint256 _maxBet) 
        external
        payable
        nonReentrant
        {
        require(
            (currentEncierroId == 10) || 
            (Encierros[currentEncierroId].status == Status.Claimable), "session not claimable");

        require(((_endTime - block.timestamp) >= minDuration) && ((_endTime - block.timestamp) <= maxDuration), "invalid time");
        require(msg.value == SEED_COST, "seed cost not met");

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
            numberOfBetsOnRunnersWinning: 0,
            numberOfBetsOnBullsWinning: 0,
            topiaBetByRunners: 0,
            topiaBetByBulls: 0,
            topiaBetByMatadors: 0,
            topiaBetOnRunners: 0,
            topiaBetOnBulls: 0,
            totalTopiaCollected: 0,
            flipResult: 2 // init to 2 to avoid conflict with 0 (bulls) or 1 (runners). is set to 0 or 1 later depending on coin flip result.
        });

        RandomizerContract.transfer(msg.value);
        
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
        MetatopiaCoinFlipRNGInterface.requestRandomWords();
        Encierros[_encierroId].status = Status.Closed;
        emit EncierroClosed(
            _encierroId,
            block.timestamp,
            Encierros[_encierroId].numRunners,
            Encierros[_encierroId].numBulls,
            Encierros[_encierroId].numMatadors,
            Encierros[_encierroId].numberOfBetsOnRunnersWinning,
            Encierros[_encierroId].numberOfBetsOnBullsWinning,
            Encierros[_encierroId].topiaBetByRunners,
            Encierros[_encierroId].topiaBetByBulls,
            Encierros[_encierroId].topiaBetByMatadors,
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
            uint256 amountToMatadors = (Encierros[_encierroId].topiaBetOnRunners * matadorCut) / 10000;
            _payMatadorTax(amountToMatadors);
        } else { // if runners win
            uint256 amountToMatadors = (Encierros[_encierroId].topiaBetOnBulls * matadorCut) / 10000;
            _payMatadorTax(amountToMatadors);
        }

        Encierros[_encierroId].status = Status.Claimable;
        return encierroFlipResult;
    }

    function _payMatadorTax(uint256 _amount) internal {
        uint256 stakedMatadors = ArenaInterface.matadorCount();
        uint256 topiaPerMatador = _amount / stakedMatadors;
        for(uint i = 0; i < matadorIds.length; i++) {
            bool isStaked = BullRunInterface.IsNFTStaked(matadorIds[i]);
            if(isStaked) {
                matadorEarnings[matadorIds[i]].owed += topiaPerMatador;
            } else {
                continue;
            }
        }
    }

    function claimMatadorEarnings(uint16[] calldata tokenIds) external nonReentrant notContract() {
        address tokenOwner;
        uint256 owed;
        for(uint i = 0; i < tokenIds.length; i++) {
            (,tokenOwner,,,) = getStakedNFTInfo(tokenIds[i]);
            require(msg.sender == tokenOwner);
            owed += matadorEarnings[tokenIds[i]].owed - matadorEarnings[tokenIds[i]].claimed;
            matadorEarnings[tokenIds[i]].claimed = matadorEarnings[tokenIds[i]].owed;
        }

        TopiaInterface.mint(msg.sender, owed);
        HubInterface.emitTopiaClaimed(msg.sender, owed);   
    }

    function getUnclaimedMatadorEarnings(uint16[] calldata tokenIds) external view returns (uint256 owed) {
        for(uint i = 0; i < tokenIds.length; i++) {
            owed += matadorEarnings[tokenIds[i]].owed - matadorEarnings[tokenIds[i]].claimed;
        }
    }

    function _flipCoin() internal returns (uint256) {
        uint256 result = MetatopiaCoinFlipRNGInterface.oneOutOfTwo();
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
}
