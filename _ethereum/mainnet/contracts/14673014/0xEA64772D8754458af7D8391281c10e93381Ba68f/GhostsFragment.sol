// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IGhostsProject.sol";
import "./IGhostMemories.sol";
import "./IRandomNumberConsumerV2.sol";
import "./IGhostMemoriesStorage.sol";

contract GhostsFragment is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    enum LotteryState{ PRE, ACTIVE, POST }

    using StringsUpgradeable for uint256;

    /// @notice Event emitted when TokenURI base changes
    /// @param tokenUriBase the base URI for tokenURI calls
    event TokenUriBaseSet(string tokenUriBase);

    uint256 internal constant MAX_FRAGMENTS = 187;
    uint256 internal constant GHOSTS_POPULATION = 10000;
    string public constant VRF_LOTTERY_KEY = "GhostsFragmentLottery";
    string public constant VRF_ORDER_KEY = "GhostsFragmentMintOrder";

    string internal baseURI;

    LotteryState public lotteryState;

    uint256[2] internal mintOrder;
    uint256[2] internal seedNumbers;

    uint256 internal countParticipants;

    mapping(uint256 => bool) private _participated;
    mapping(uint256 => bool) private _lotteryWon;

    IGhostsProject private ghostsProject;
    IRandomNumberConsumerV2 private vrfContract;
    IGhostMemories private goodMemories;
    IGhostMemories private evilMemories;
    IGhostMemoriesStorage private memoriesStorage;

    modifier onlyGhostOwner(uint256 _tokenId, address _ownerAddress) {
        require(_ownerAddress == ghostsProject.ownerOf(_tokenId), "Not a ghost owner");
        _;
    }

    modifier lotteryActive() {
        require(lotteryState == LotteryState.ACTIVE, "Not in active state");
        _;
    }

    function initialize() initializer public {
        __ERC721_init_unchained("Fragment", "FRAGMENT");
        __Ownable_init_unchained();
    }

    function isGhostsFragment() external pure returns (bool) {
        return true;
    }

    function connectGhostsProject(address _address) public onlyOwner {
        IGhostsProject candidateContract = IGhostsProject(_address);
        require(candidateContract.isGhostsProject());
        ghostsProject = IGhostsProject(_address);
    }

    function connectVRFContract(address _address) public onlyOwner {
        IRandomNumberConsumerV2 candidateContract = IRandomNumberConsumerV2(_address);
        require(candidateContract.isVRFContract());
        vrfContract = IRandomNumberConsumerV2(_address);
    }

    function connectGoodMemories(address _address) public onlyOwner {
        IGhostMemories candidateContract = IGhostMemories(_address);
        require(keccak256(abi.encodePacked(candidateContract.getMemoryType())) == keccak256(abi.encodePacked("Good")), "");
        goodMemories = IGhostMemories(_address);
    }

    function connectEvilMemories(address _address) public onlyOwner {
        IGhostMemories candidateContract = IGhostMemories(_address);
        require(keccak256(abi.encodePacked(candidateContract.getMemoryType())) == keccak256(abi.encodePacked("Evil")), "");
        evilMemories = IGhostMemories(_address);
    }

    function connectMemoriesStorage(address _address) public onlyOwner {
        IGhostMemoriesStorage candidateContract = IGhostMemoriesStorage(_address);
        require(candidateContract.isStorageContract());
        memoriesStorage = IGhostMemoriesStorage(_address);
    }

    function isGoodMemoriesConnected() public view returns (bool) {
        return keccak256(abi.encodePacked(goodMemories.getMemoryType())) == keccak256(abi.encodePacked("Good"));
    }

    function isEvilMemoriesConnected() public view returns (bool) {
        return keccak256(abi.encodePacked(evilMemories.getMemoryType())) == keccak256(abi.encodePacked("Evil"));
    }

    function isGhostsProjectConnected() public view returns (bool) {
        return ghostsProject.isGhostsProject();
    }

    function isVRFConnected() public view returns (bool) {
        return vrfContract.isVRFContract();
    }

    function isMemoriesStorageConnected() public view returns (bool) {
        return memoriesStorage.isStorageContract();
    }

    function getMaxSupply() public pure returns (uint256) {
        return MAX_FRAGMENTS;
    }

    function getLotteryState() public view returns (uint256) {
        return uint256(lotteryState);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function setTokenUriBase(string calldata _tokenUriBase) public onlyOwner {
        baseURI = _tokenUriBase;
        emit TokenUriBaseSet(baseURI);
    }

    function _setMintOrder(uint256[] memory _randoms) public onlyOwner {
        require(mintOrder[0] == 0, "already filled seed numbers");
        require(_randoms.length == 2, "seed numbers should be two numbers");
        uint256 rn = (_randoms[0] == 0) ? 1 :_randoms[0];
        while (rn % 7 == 0) {
            rn = rn / 7;
        }
        while (rn % 11 == 0) {
            rn = rn / 11;
        }
        mintOrder[0] = rn;
        mintOrder[1] = _randoms[1];
    }

    function setMintOrder() public onlyOwner {
        uint256[] memory rn = vrfContract.getRandomWords(VRF_ORDER_KEY);
        _setMintOrder(rn);
    }

    function _setSeedNumbersForRNG(uint256[] memory _randoms) public onlyOwner {
        require(seedNumbers[0] == 0, "already filled seed numbers");
        require(_randoms.length == 2, "seed numbers should be two numbers");
        seedNumbers[0] = (_randoms[0] == 0) ? 1 : _randoms[0];
        seedNumbers[1] = _randoms[1];
    }

    function setSeedNumbersForRNG() public onlyOwner {
        uint256[] memory rn = vrfContract.getRandomWords(VRF_LOTTERY_KEY);
        _setSeedNumbersForRNG(rn);
    }

    function _getRandomNumberForGhost(uint256 _ghostId) internal view returns (uint256) {
        return ((seedNumbers[0] % GHOSTS_POPULATION) * _ghostId + seedNumbers[1]) % GHOSTS_POPULATION;
    }

    function hasCorrectMemory(uint256 _ghostId) public view returns (bool) {
        string memory memoryPicked = memoriesStorage.getChosenMemory(_ghostId);
        uint256 memoryType = memoriesStorage.getMemoryType(_ghostId);
        string memory memoryRaw;
        if (memoryType == 1) {
            memoryRaw = goodMemories.getMemoryAndFlashbackByGhostId(_ghostId);
        } else {
            memoryRaw = evilMemories.getMemoryAndFlashbackByGhostId(_ghostId);
        }
        return keccak256(abi.encodePacked(memoryPicked)) == keccak256(abi.encodePacked(memoryRaw));
    }

    function getNewTokenId() internal view returns (uint256) {
        return ((mintOrder[0] % MAX_FRAGMENTS) * totalSupply() + mintOrder[1]) % MAX_FRAGMENTS + 1;
    }

    function runLottery(uint256 _ghostId, address _ownerAddress) public onlyGhostOwner(_ghostId, _ownerAddress) lotteryActive {
        require(!_participated[_ghostId], "Already participated");
        require(hasCorrectMemory(_ghostId), "Picked wrong memories");
        _participated[_ghostId] = true;
        countParticipants += 1;
        uint256 myNum = _getRandomNumberForGhost(_ghostId);
        uint256 currentSupply = totalSupply();
        if (myNum * (GHOSTS_POPULATION - countParticipants) < (MAX_FRAGMENTS - currentSupply) * GHOSTS_POPULATION) {
            _lotteryWon[_ghostId] = true;

            _safeMint(_ownerAddress, getNewTokenId());
        } else {
            _lotteryWon[_ghostId] = false;
        }
    }

    function runLotteryBatch(uint256[] memory _ghostIds, address _ownerAddress) public lotteryActive {
        for (uint256 idx = 0; idx < _ghostIds.length; idx++) {
            runLottery(_ghostIds[idx], _ownerAddress);
        }
    }

    function hasParticipatedLottery(uint256 _ghostId) public view returns (bool) {
        return _participated[_ghostId];
    }

    function getLotteryResult(uint256 _ghostId) public view returns (bool) {
        return _lotteryWon[_ghostId];
    }

    function updateLotteryState(LotteryState newState) public onlyOwner {
        require(lotteryState != newState, "can't change to same state");
        require(mintOrder[0] > 0, "set mint order first");
        lotteryState = newState;
    }

    function mintFragmentsByAdmin(uint256 numToken) public onlyOwner {
        for (uint256 idx = 0; idx < numToken; idx++) {
            if (totalSupply() >= MAX_FRAGMENTS)
                break;
            _safeMint(msg.sender, getNewTokenId());
        }
    }
}
