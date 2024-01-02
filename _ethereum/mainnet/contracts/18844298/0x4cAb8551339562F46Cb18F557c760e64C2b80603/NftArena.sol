// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./MerkleProof.sol";
import "./IERC721.sol";
import "./VRFCoordinatorV2Interface.sol";

import "./VRFConsumerBaseV2Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./NftArenazPowersInterface.sol";

contract NftArena is Initializable, VRFConsumerBaseV2Upgradeable, ERC721HolderUpgradeable, UUPSUpgradeable, OwnableUpgradeable {

    uint8 constant public ARENA_SIZE = 6;

    enum GameStatus {
        WaitingForPlayers,      // Player created a game and is waiting for opponent
        InProgress,             // Game aleady started and is waiting for RNG to complete
        Completed,              // Game winner is selected but still hasn't withdrawn won NFTS
        CompletedAndClaimed     // Game winner claimed won tokens
    }
    struct Player {
        address playerAddress;
        uint256 nftId;
        uint256 nftPower;
        uint256 joinedTimestamp;
    }
    struct Game {
        uint256 id;
        address nftContractAddress;
        Player[ARENA_SIZE] players;
        Player winner;
        GameStatus status;
        uint256 timestamp;
    }
    struct GameReference {
        address nftContractAddress;
        uint256 gameId;
    }
    struct CommissionNft {
        uint256 nftId;
        bool claimed;
    }

    mapping(address => mapping(uint256 => Game)) public games;
    mapping(address => uint256) public gameCount;
    mapping(address => uint256) public joinFees;
    mapping(address => uint256) public claimFees;
    mapping(uint256 => GameReference) private randomnessRequestsToGameIds;
    mapping(address => uint8) public currentNumberOfParticipants;
    mapping(address => uint256) public numberOfWithdrawnNfts;
    mapping(address => mapping (uint256 => CommissionNft)) public commissionNfts;

    event PlayerJoinedGame(address indexed nftContractAddress, uint256 gameId, address playerAddress, uint256 playerNft, uint8 slot, uint256 timestamp);
    event PlayerLeftGame(address indexed nftContractAddress, uint256 gameId, uint256 playerNft);
    event PlayerClaimedPrize(address indexed nftContractAddress, uint256 gameId);
    event GameCompleted(address indexed nftContractAddress, uint256 gameId, uint256 winnerNft, uint256 loserNft);

    uint256 public nftLockTimeInMinutes;
    bytes32 public clMaxGasKeyHash;
    NftArenazPowersInterface public nftArenazPowers;
    uint64 public clSubscriptionId;
    uint32 public clCallbackGasLimit;
    uint16 public clRequestConfirmations;
    bool public isContractEnabled;
    VRFCoordinatorV2Interface public clCoordinator;

    function initialize(
        uint64 subscriptionId,
        address coordinatorAddress,
        bytes32 maxGasKeyHash,
        uint16 requestConfirmations,
        address nftArenazPowersAddress
    ) public initializer
    {
        isContractEnabled = true;
        clCallbackGasLimit = 2_500_000;
        clCoordinator = VRFCoordinatorV2Interface(coordinatorAddress);
        clSubscriptionId = subscriptionId;
        clMaxGasKeyHash = maxGasKeyHash;
        clRequestConfirmations = requestConfirmations;
        nftArenazPowers = NftArenazPowersInterface(nftArenazPowersAddress);
        nftLockTimeInMinutes = 60 * 24;

       __Ownable_init();
       __VRFConsumerBaseV2_init(coordinatorAddress);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    //
    // PUBLIC API
    function getCommissionNftsBatch(address projectAddress, uint256 startIndex, uint256 batchSize) public view returns (CommissionNft[] memory) {
        require(startIndex < gameCount[projectAddress], "Start index is out of bounds");
        require(batchSize > 0, "Batch size must be greater than zero");

        uint256 arraySize = gameCount[projectAddress] - startIndex < batchSize
            ? gameCount[projectAddress] - startIndex
            : batchSize;
        CommissionNft[] memory commissionNftList = new CommissionNft[](arraySize);

        uint256 endIndex = startIndex + batchSize;
        for (uint i = startIndex; i < endIndex && i < gameCount[projectAddress]; i++) {
            commissionNftList[i - startIndex] = commissionNfts[projectAddress][i];
        }

        return commissionNftList;
    }

    function getGamesBatch(address projectAddress, uint256 startIndex, uint256 batchSize) public view returns (Game[] memory) {
        require(startIndex <= gameCount[projectAddress], "Start index is out of bounds");
        require(batchSize > 0, "Batch size must be greater than zero");

        uint256 arraySize = gameCount[projectAddress] + 1 - startIndex < batchSize
            ? gameCount[projectAddress] + 1 - startIndex
            : batchSize;
        Game[] memory gameList = new Game[](arraySize);

        uint256 endIndex = startIndex + batchSize;
        for (uint256 i = startIndex; i < endIndex && i < gameCount[projectAddress] + 1; i++) {
            gameList[i - startIndex] = games[projectAddress][i];
        }

        return gameList;
    }

    function joinArena(
        address nftContractAddress,
        uint8 slotIndex,
        uint256 nftId,
        uint256 nftPower,
        bytes32[] calldata nftPowerMerkleProof) public payable
    {
        require(isContractEnabled, "Game is currently disabled");
        require(games[nftContractAddress][gameCount[nftContractAddress]].players[slotIndex].playerAddress == address(0), "Selected slot is already taken");
        require(games[nftContractAddress][gameCount[nftContractAddress]].status == GameStatus.WaitingForPlayers, "Game with given id doesn't exist or is already in progress");
        require(msg.value >= joinFees[nftContractAddress], "Provided fee is too low");
        require(nftArenazPowers.verifyNftPower(nftPowerMerkleProof, nftId, nftPower, nftContractAddress), "Invalid nft power proof");

        IERC721 nftContract = IERC721(nftContractAddress);
        requireNftApprovalAndOwnership(nftContract, nftId);

        currentNumberOfParticipants[nftContractAddress]++;
        games[nftContractAddress][gameCount[nftContractAddress]].nftContractAddress = nftContractAddress;
        games[nftContractAddress][gameCount[nftContractAddress]].players[slotIndex] = Player(msg.sender, nftId, nftPower, block.timestamp);
        games[nftContractAddress][gameCount[nftContractAddress]].timestamp = block.timestamp;

        nftContract.transferFrom(msg.sender, address(this), nftId);
        emit PlayerJoinedGame(nftContractAddress, gameCount[nftContractAddress], msg.sender, nftId, slotIndex, block.timestamp);

        if(currentNumberOfParticipants[nftContractAddress] == ARENA_SIZE) {
            games[nftContractAddress][gameCount[nftContractAddress]].status = GameStatus.InProgress;
            requestRandomWords(nftContractAddress, gameCount[nftContractAddress]);
        }
    }

    function leaveArena(address nftContractAddress, uint256 nftId, uint8 slotIndex) public
    {
        require(games[nftContractAddress][gameCount[nftContractAddress]].status == GameStatus.WaitingForPlayers, "Game is already in progress");
        require(
            games[nftContractAddress][gameCount[nftContractAddress]].players[slotIndex].playerAddress == msg.sender && 
            games[nftContractAddress][gameCount[nftContractAddress]].players[slotIndex].nftId == nftId,
            "You are not participating in the game with provided NFT"
        );
        require(
            block.timestamp >= games[nftContractAddress][gameCount[nftContractAddress]].players[slotIndex].joinedTimestamp + nftLockTimeInMinutes * 1 minutes, 
            "Tokens are locked and can only be withdrawn after lock time has passed since joining"
        );

        IERC721 nftContract = IERC721(nftContractAddress);
        games[nftContractAddress][gameCount[nftContractAddress]].timestamp = block.timestamp;
        games[nftContractAddress][gameCount[nftContractAddress]].players[slotIndex] = Player(address(0), 0, 0, 0);
        currentNumberOfParticipants[nftContractAddress]--;

        nftContract.transferFrom(address(this), msg.sender, nftId);
        emit PlayerLeftGame(nftContractAddress, gameCount[nftContractAddress], nftId);
    }

    function claimPrize(address nftContractAddress, uint256 gameId) public payable {
        require(games[nftContractAddress][gameId].status == GameStatus.Completed, "Game with given id isn't completed yet or NFTs have already been claimed");
        require(games[nftContractAddress][gameId].winner.playerAddress == msg.sender, "You are not a winner of this game");
        require(msg.value >= claimFees[nftContractAddress], "Provided fee is too low");

        games[nftContractAddress][gameId].status = GameStatus.CompletedAndClaimed;

        IERC721 nftContract = IERC721(nftContractAddress);
        for (uint8 i = 0; i < ARENA_SIZE; i++) {
            if (games[nftContractAddress][gameId].players[i].nftId != commissionNfts[nftContractAddress][gameId].nftId) {
                nftContract.transferFrom(address(this), msg.sender, games[nftContractAddress][gameId].players[i].nftId);
            }
        }

        emit PlayerClaimedPrize(games[nftContractAddress][gameId].nftContractAddress, gameId);
    }

    function requestRandomWords(address nftContractAddress, uint256 gameId) private
    {
        uint256 requestId = clCoordinator.requestRandomWords(
            clMaxGasKeyHash,
            clSubscriptionId,
            clRequestConfirmations,
            clCallbackGasLimit,
            1 // number of requested random values
        );
        randomnessRequestsToGameIds[requestId] = GameReference(nftContractAddress, gameId);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        uint256 gameId = randomnessRequestsToGameIds[_requestId].gameId;
        address nftContractAddress = randomnessRequestsToGameIds[_requestId].nftContractAddress;
        require(games[nftContractAddress][gameId].status == GameStatus.InProgress, "Game with given id is not in progress.");

        games[nftContractAddress][gameId].status = GameStatus.Completed;
        games[nftContractAddress][gameId].timestamp = block.timestamp;

        uint256 totalNftPower = 0;
        for (uint8 i = 0; i < ARENA_SIZE; i++) {
            totalNftPower += games[nftContractAddress][gameId].players[i].nftPower;
        }

        uint256 randomResult = _randomWords[0] % totalNftPower;
        uint256 powerTreshold = 0;
        for (uint8 i = 0; i < ARENA_SIZE; i++) {
            powerTreshold += games[nftContractAddress][gameId].players[i].nftPower;
            if (randomResult < powerTreshold) {
                games[nftContractAddress][gameId].winner = games[nftContractAddress][gameId].players[i];
                break;
            }
        }
        
        Player memory loserPlayer = games[nftContractAddress][gameId].players[0].nftId == games[nftContractAddress][gameId].winner.nftId
            ? games[nftContractAddress][gameId].players[1]
            : games[nftContractAddress][gameId].players[0];
        for (uint8 i = 1; i < ARENA_SIZE; i++) {
            loserPlayer = games[nftContractAddress][gameId].players[i].nftId != games[nftContractAddress][gameId].winner.nftId 
                && games[nftContractAddress][gameId].players[i].nftPower < loserPlayer.nftPower
                    ? games[nftContractAddress][gameId].players[i]
                    : loserPlayer;
        }
        commissionNfts[nftContractAddress][gameId] = CommissionNft(loserPlayer.nftId, false);

        gameCount[nftContractAddress]++;
        currentNumberOfParticipants[nftContractAddress] = 0;
        games[nftContractAddress][gameCount[nftContractAddress]].id = gameCount[nftContractAddress];

        emit GameCompleted(nftContractAddress, gameId, games[nftContractAddress][gameId].winner.nftId, loserPlayer.nftId);
    }

    function requireNftApprovalAndOwnership(IERC721 nftContract, uint256 nftId) private view {
        require(nftContract.ownerOf(nftId) == msg.sender, "You are not the owner of the NFT");
        require(nftContract.isApprovedForAll(msg.sender, address(this)), "Approval for NFT was not set");
    }

    /**
     * OWNER ONLY API
     **/

    function retryRandomWordsRequest(address nftContractAddress, uint256 gameId) external onlyOwner {
        require(games[nftContractAddress][gameId].status == GameStatus.InProgress, "Game with given id is not in progress.");
        requestRandomWords(nftContractAddress, gameId);
    }

    function setVrfCoordinator(address vrfCoordinator) external onlyOwner
    {
        clCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    function setSubscriptionId(uint64 subscriptionId) external onlyOwner
    {
        clSubscriptionId = subscriptionId;
    }

    function setCallbackGasLimit(uint32 callbackGasLimit) external onlyOwner
    {
        clCallbackGasLimit = callbackGasLimit;
    }

    function setMaxGasKeyHash(bytes32 maxGasKeyHash) external onlyOwner
    {
        clMaxGasKeyHash = maxGasKeyHash;
    }

    function setRequestConfirmations(uint16 requestConfirmations) external onlyOwner
    {
        clRequestConfirmations = requestConfirmations;
    }

    function setFees(address nftProjectAddress, uint256 joinFee, uint256 claimFee) external onlyOwner
    {
        joinFees[nftProjectAddress] = joinFee;
        claimFees[nftProjectAddress] = claimFee;
    }

    function setJoinFee(address nftProjectAddress, uint256 joinFee) external onlyOwner
    {
        joinFees[nftProjectAddress] = joinFee;
    }

    function setClaimFee(address nftProjectAddress, uint256 claimFee) external onlyOwner
    {
        claimFees[nftProjectAddress] = claimFee;
    }

    function triggerContract() external onlyOwner
    {
        isContractEnabled = !isContractEnabled;
    }

    function withdraw() external onlyOwner  {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawNftFees(address nftContractAddress, uint256 numberOfTokens) external onlyOwner
    {
        require(numberOfTokens > 0, "Number of tokens to withdraw must be greater than 0");
        require(
            numberOfWithdrawnNfts[nftContractAddress] + numberOfTokens <= gameCount[nftContractAddress],
            "Number of tokens exceeded number of available commission NFTs"
        );

        IERC721 nftContract = IERC721(nftContractAddress);
        uint256 gameId = numberOfWithdrawnNfts[nftContractAddress];
        numberOfWithdrawnNfts[nftContractAddress] = numberOfWithdrawnNfts[nftContractAddress] + numberOfTokens;
        
        while(gameId < numberOfWithdrawnNfts[nftContractAddress]) {
            commissionNfts[nftContractAddress][gameId].claimed = true;
            nftContract.transferFrom(address(this), msg.sender, commissionNfts[nftContractAddress][gameId].nftId);
            gameId++;
        }
    }

    function changeNftLockTimeInMinutes(uint16 _nftLockTimeInMinutes) external onlyOwner
    {
        nftLockTimeInMinutes = _nftLockTimeInMinutes;
    }
}
