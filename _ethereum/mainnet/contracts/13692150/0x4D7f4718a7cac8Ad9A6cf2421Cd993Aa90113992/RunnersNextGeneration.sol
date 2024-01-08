// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ChainRunnersTypes.sol";
import "./IChainRunnersRenderer.sol";
import "./IChainRunners.sol";

/*
  _____
 |  __ \                                _
 | |__) |   _ _ __  _ __   ___ _ __ ___(_)
 |  _  / | | | '_ \| '_ \ / _ \ '__/ __|
 | | \ \ |_| | | | | | | |  __/ |  \__ \_
 |_|  \_\__,_|_| |_|_| |_|\___|_|  |___(_)               _   _
 | \ | |         | |    / ____|                         | | (_)
 |  \| | _____  _| |_  | |  __  ___ _ __   ___ _ __ __ _| |_ _  ___  _ __
 | . ` |/ _ \ \/ / __| | | |_ |/ _ \ '_ \ / _ \ '__/ _` | __| |/ _ \| '_ \
 | |\  |  __/>  <| |_  | |__| |  __/ | | |  __/ | | (_| | |_| | (_) | | | |
 |_| \_|\___/_/\_\\__|  \_____|\___|_| |_|\___|_|  \__,_|\__|_|\___/|_| |_|


Make Love Not War. Break The Chain.
    made by abranti.eth (twitter.com/joaoabrantis)
*/

contract RunnersNextGeneration is ERC721Enumerable, Ownable, ReentrancyGuard {
    struct Parents {
        uint256 parentA;
        uint256 parentB;
    }

    uint256 private constant NUM_LAYERS = 13;
    address public genesisContractAddress = 0x97597002980134beA46250Aa0510C9B90d87A587;
    address public renderingContractAddress = 0xfDac77881ff861fF76a83cc43a1be3C317c6A1cC;

    mapping(uint256 => ChainRunnersTypes.ChainRunner) runners;

    uint256 private constant MAX_RUNNERS = 10000;

    mapping(uint256 => uint256) public lastBreeding;
    mapping(uint256 => Parents) public parentsOf;
    mapping(uint256 => uint256) public crush;
    mapping(uint256 => uint256) public dowry;

    event GotACrush(uint256 indexed chainRunnerInLove, uint256 indexed lovedChainRunner, uint256 dowry);
    event HadAChild(uint256 indexed parentA, uint256 indexed parentB, uint256 dowry, uint256 childId, uint256 dna);
    event DowryWasZeroed(uint256 indexed chainRunner);

    constructor() ERC721("Runners: Next Generation", "RNG") {}

    function announceLove(uint256 chainRunnerInLove, uint256 lovedChainRunner) external payable {
        IChainRunners genesis = IChainRunners(genesisContractAddress);
        require(lovedChainRunner > 0 && lovedChainRunner <= MAX_RUNNERS, "Lover not found");
        require(genesis.ownerOf(chainRunnerInLove) == msg.sender, "Not your CR");
        require(chainRunnerInLove != lovedChainRunner, "Love the other");

        crush[chainRunnerInLove] = lovedChainRunner;
        dowry[chainRunnerInLove] += msg.value;
        emit GotACrush(chainRunnerInLove, lovedChainRunner, dowry[chainRunnerInLove]);
    }

    function mate(uint256 myChainRunnerId, uint256 myLoverId) external nonReentrant {
        IChainRunners genesis = IChainRunners(genesisContractAddress);
        require(tx.origin == msg.sender, "No contracts");
        require(totalSupply() < MAX_RUNNERS, "Gen closed");
        require(genesis.ownerOf(myChainRunnerId) == msg.sender, "Not your CR");
        require(crush[myLoverId] == myChainRunnerId, "Love not reciprocal");

        // each runner needs a day to recharge after an intense mating session - @dozer
        require(lastBreeding[myChainRunnerId] + 1 days < block.timestamp, "You need rest");
        require(lastBreeding[myLoverId] + 1 days < block.timestamp, "Lover needs rest");

        uint256 myDna = genesis.getDna(myChainRunnerId);
        uint256 loverDna = genesis.getDna(myLoverId);
        uint256 rand = uint256(keccak256(abi.encodePacked(myChainRunnerId, myLoverId, msg.sender, block.difficulty, block.timestamp)));
        uint256 childDna = crossover(myDna, loverDna, rand);

        lastBreeding[myChainRunnerId] = block.timestamp;
        lastBreeding[myLoverId] = block.timestamp;

        uint256 tokenId = totalSupply() + 1;

        parentsOf[tokenId] = Parents(myChainRunnerId, myLoverId);
        ChainRunnersTypes.ChainRunner memory runner;
        runner.dna = childDna;
        runners[tokenId] = runner;

        _safeMint(genesis.ownerOf(myLoverId), tokenId);

        uint256 dowryReceived = dowry[myLoverId];
        if (dowryReceived > 0){
            dowry[myLoverId] = 0;
            (bool success,) = msg.sender.call{value : dowryReceived}('');
            require(success, "Dowry failed");
        }

        emit HadAChild(myChainRunnerId, myLoverId, dowryReceived, tokenId, childDna);
    }

    function splitNumber(uint256 _number) internal pure returns (uint16[NUM_LAYERS] memory numbers) {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % 10000);
            _number >>= 14;
        }
        return numbers;
    }

    function assembleDna(uint16[NUM_LAYERS] memory numbers) internal pure returns (uint256) {
        uint256 dna;
        uint256 t;
        uint256 r;
        uint256 n;
        for (uint256 i = 0; i < NUM_LAYERS; i++){
            n = numbers[NUM_LAYERS-1-i]; // reverse
            t = dna % 10000;
            r = t <= n ? n - t : 10000 + n - t;
            dna += r;
            if (i != NUM_LAYERS - 1){
                dna <<= 14;
            }
        }
        return dna;
    }

    function crossover(uint256 myDna, uint256 loverDna, uint256 rand) internal pure returns (uint256) {
        uint16[NUM_LAYERS] memory childNumbers;
        uint16[NUM_LAYERS] memory parentA = splitNumber(myDna);
        uint16[NUM_LAYERS] memory parentB = splitNumber(loverDna);

        // possible children 2**13 = 8192
        for (uint8 i=0; i < NUM_LAYERS; i++) {
            if ((rand >> i) % 2 == 0) {
                childNumbers[i] = parentA[i];
            } else {
                childNumbers[i] = parentB[i];
            }
        }
        return assembleDna(childNumbers);
    }

    function getDna(uint256 _tokenId) public view returns (uint256) {
        return runners[_tokenId].dna;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        IChainRunnersRenderer renderer = IChainRunnersRenderer(renderingContractAddress);
        return renderer.tokenURI(_tokenId, runners[_tokenId]);
    }

    function withdrawDowry(uint256 chainRunnerId) external nonReentrant {
        IChainRunners genesis = IChainRunners(genesisContractAddress);
        require(genesis.ownerOf(chainRunnerId) == msg.sender, "Not your CR");
        uint256 value = dowry[chainRunnerId];
        dowry[chainRunnerId] = 0;
        (bool success,) = msg.sender.call{value : value}('');
        require(success, "Withdrawal failed");
        emit DowryWasZeroed(chainRunnerId);
    }
}