// AvailableWorks.sol
// For Darren Bader Available works, written by wk0
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract AvailableWorks is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, VRFConsumerBaseV2 {
    using Strings for uint256;
    // VRF
    // ---------------------------------------------
    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;
    // ---------------------------------------------

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIndexCounter;

    uint256 public constant MAX_TOKENS = 72;
    uint256 public TOKEN_PRICE = 170000000000000000;
    uint256 private constant BURN_ID = 69;

    uint256[MAX_TOKENS] private tokenIds;
    bool public randomized = false;
    bool public specialInitFlag = false;

    string public BASE_URI;

    // 'Burn' mechanics
    bool[MAX_TOKENS] public tokenBurned;

    // benefits
    mapping(address => uint256) public beneficiaryBalance;
    address[3] private beneficiaryList;

    // VRF
    // ---------------------------------------------
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 immutable s_callbackGasLimit = 100000;
    uint16 immutable s_requestConfirmations = 3;
    uint32 immutable s_numWords = 1;

    uint256 public s_randomWord;
    uint256 public s_requestId;

    event ReturnedRandomness(uint256[] randomWords);

    // ---------------------------------------------

    constructor(
        string memory baseUri,
        address beneficiary,
        address[3] memory benefitList,
        uint64 subscriptionId,
        address vrfCoordinator,
        address link,
        bytes32 keyHash
    ) ERC721("Available Works", "DBAW") VRFConsumerBaseV2(vrfCoordinator) {
        transferOwnership(beneficiary);
        require(owner() == beneficiary, "Ownership not transferred");
        // VRF
        // ---------------------------------------------
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        // ---------------------------------------------
        // NFTs
        BASE_URI = baseUri;

        // benefits
        beneficiaryList = benefitList;

        tokenIds[0] = BURN_ID;
        // Initialize tokenIds in order
        for (uint256 i = 0; i < MAX_TOKENS; i++) {
            if (i < BURN_ID) {
                tokenIds[i + 1] = i;
            } else if (i > BURN_ID) {
                tokenIds[i] = i;
            }
        }
    }

    function mockRandomize() public onlyOwner {
        randomized = true;
    }

    function randomizeTokenIds() public onlyOwner returns (bool) {
        // start at 1 to keep special card unrandomized
        for (uint256 i = 1; i < MAX_TOKENS; i++) {
            uint256 n = i + (uint256(keccak256(abi.encodePacked(s_randomWord))) % (MAX_TOKENS - i));
            uint256 temp = tokenIds[n];
            tokenIds[n] = tokenIds[i];
            tokenIds[i] = temp;
        }
        randomized = true;
        return randomized;
    }

    function getArray() external view onlyOwner returns (uint256[MAX_TOKENS] memory) {
        return tokenIds;
    }

    function mintCount() external view returns (uint256) {
        return _tokenIndexCounter.current();
    }

    function specialInit(address to) public onlyOwner returns (uint256, string memory) {
        require(!specialInitFlag, "Special init already toggled");
        uint256 tokenIndex = _tokenIndexCounter.current();
        require(tokenIndex == 0); // index of special card
        _tokenIndexCounter.increment();

        uint256 tokenId = tokenIds[tokenIndex];
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());
        string memory _tokenURI = tokenURI(tokenId);

        specialInitFlag = true;

        return (tokenId, _tokenURI);
    }

    function safeMint(address to) public payable returns (uint256, string memory) {
        require(randomized, "Token ordering not yet randomized");
        require(specialInitFlag, "Special init not yet completed");
        uint256 tokenIndex = _tokenIndexCounter.current();
        require(tokenIndex < MAX_TOKENS, "Max supply exceeded");
        require(TOKEN_PRICE <= msg.value, "Ether value sent is not correct");

        _tokenIndexCounter.increment();
        uint256 tokenId = tokenIds[tokenIndex];
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());

        string memory _tokenURI = tokenURI(tokenId);

        uint256 thousandth = msg.value / 1000;
        beneficiaryBalance[beneficiaryList[0]] += thousandth * 333;
        beneficiaryBalance[beneficiaryList[1]] += thousandth * 333;
        beneficiaryBalance[beneficiaryList[2]] += thousandth * 333;

        return (tokenId, _tokenURI);
    }

    function withdrawBenefit() external returns (bool) {
        require(
            msg.sender == beneficiaryList[0] || msg.sender == beneficiaryList[1] || msg.sender == beneficiaryList[2],
            "Address not a beneficiary"
        );
        require(beneficiaryBalance[msg.sender] > 0, "No benefits to withdraw");

        uint256 amount = beneficiaryBalance[msg.sender];
        beneficiaryBalance[msg.sender] = 0; // Optimistic accounting.
        (bool success, ) = msg.sender.call{ value: amount }("");
        require(success, "Transfer failed.");
        return success;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function viewBenefit() external view returns (uint256) {
        return beneficiaryBalance[msg.sender];
    }

    function setNotAvailable(uint256 tokenId) external onlyBurnController {
        require(tokenId < MAX_TOKENS, "tokenId exceeds maximum");
        require(!tokenBurned[tokenId], "token already burned");
        tokenBurned[tokenId] = true;
    }

    function getTokens() external view onlyBurnController returns (uint256[MAX_TOKENS] memory) {
        return tokenIds;
    }

    function getBurnController() external view returns (address) {
        require(specialInitFlag, "Special init not yet completed");
        return super.ownerOf(BURN_ID);
    }

    modifier onlyBurnController() {
        require(msg.sender == super.ownerOf(BURN_ID), "Must be burn controller");
        _;
    }

    // VRF
    // ---------------------------------------------
    /**
     * @notice Requests randomness
     * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     */
    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param requestId - id of the request (unused)
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        s_randomWord = randomWords[0];
        emit ReturnedRandomness(randomWords);
    }

    // ---------------------------------------------

    // Opensea Contract Override
    function contractURI() public view returns (string memory) {
        return "ipfs://QmUg6LAcQZ9H7PrdFeJddMFSrvmJ8TsHdHjoSb1SSkajye";
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        if (tokenBurned[tokenId]) {
            return super.tokenURI(BURN_ID);
        }
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
