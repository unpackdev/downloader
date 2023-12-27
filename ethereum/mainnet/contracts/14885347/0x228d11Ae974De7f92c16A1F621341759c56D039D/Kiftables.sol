// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./ERC721A.sol";
import "./BatchReveal.sol";

contract Kiftables is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    VRFConsumerBaseV2,
    BatchReveal
{
    string public baseURI;
    string public preRevealBaseURI;
    string public verificationHash;
    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive = true;
    address private gnosisSafe;

    uint256 public constant MAX_KIFTABLES_PER_WALLET = 5;
    uint256 public constant maxKiftables = 10000;
    uint256 public constant maxCommunitySaleKiftables = 7000;
    uint256 public constant maxTreasuryKiftables = 1000;
    bool public treasuryMinted = false;

    uint256 public constant PUBLIC_SALE_PRICE = 0.1 ether;
    bool public isPublicSaleActive = false;

    uint256 public constant COMMUNITY_SALE_PRICE = 0.08 ether;
    bool public isCommunitySaleActive = false;
    bytes32 public communityListMerkleRoot;
    mapping(address => uint256) public communityMintCounts;
    mapping(address => uint256) public airdropCounts;

    // Constants from https://docs.chain.link/docs/vrf-contracts/
    VRFCoordinatorV2Interface COORDINATOR;
    bytes32 private immutable s_keyHash;
    uint64 private immutable s_subscriptionId;

    // ============ EVENTS ============

    event MintTreasury();
    event Airdrop(address indexed to, uint256 indexed amount);

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not active");
        _;
    }

    modifier communitySaleActive() {
        require(isCommunitySaleActive, "Community sale is not active");
        _;
    }

    modifier maxKiftablesPerWallet(uint256 numberOfTokens) {
        uint256 numAirdropped = airdropCounts[msg.sender];
        require(
            numberOfTokens <= MAX_KIFTABLES_PER_WALLET &&
                balanceOf(msg.sender) - numAirdropped + numberOfTokens <=
                MAX_KIFTABLES_PER_WALLET,
            "Max Kiftables to mint is five"
        );
        _;
    }

    modifier canMintKiftables(uint256 numberOfTokens) {
        require(
            _totalMinted() + numberOfTokens <= maxKiftables,
            "Not enough Kiftables remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not in list or incorrect proof"
        );
        _;
    }

    constructor(
        string memory _preRevealURI,
        bytes32 _s_keyHash,
        address _vrfCoordinator,
        uint64 _s_subscriptionId,
        address _openSeaProxyRegistryAddress,
        address _gnosisSafe
    ) ERC721A("Kiftables", "KIFT") VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_keyHash = _s_keyHash;
        s_subscriptionId = _s_subscriptionId;
        preRevealBaseURI = _preRevealURI;
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        gnosisSafe = _gnosisSafe;
    }

    // ============ Treasury ============

    function treasuryMint() public onlyOwner {
        require(treasuryMinted == false, "Treasury can only be minted once");
        _safeMint(gnosisSafe, maxTreasuryKiftables);
        treasuryMinted = true;
        emit MintTreasury();
    }

    // ============ Airdrop ============

    function airdrop(address _to, uint256[] memory _tokenIds) public onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            airdropCounts[_to]++;
            safeTransferFrom(msg.sender, _to, _tokenIds[i]);
        }
        emit Airdrop(_to, _tokenIds.length);
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens)
        public
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        publicSaleActive
        canMintKiftables(numberOfTokens)
        maxKiftablesPerWallet(numberOfTokens)
    {
        _safeMint(msg.sender, numberOfTokens);
    }

    // TODO put back to uint8
    function mintCommunitySale(
        uint256 numberOfTokens,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        communitySaleActive
        canMintKiftables(numberOfTokens)
        isCorrectPayment(COMMUNITY_SALE_PRICE, numberOfTokens)
        isValidMerkleProof(merkleProof, communityListMerkleRoot)
    {
        uint256 numAlreadyMinted = communityMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_KIFTABLES_PER_WALLET,
            "Max Kiftables to mint in community sale is five"
        );

        require(
            _totalMinted() + numberOfTokens <= maxCommunitySaleKiftables,
            "Not enough Kiftables remaining to mint in community sale"
        );

        communityMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        _safeMint(msg.sender, numberOfTokens);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function nextTokenId() external view returns (uint256) {
        return _totalMinted();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setPreRevealURI(string memory _prerevealURI) external onlyOwner {
        preRevealBaseURI = _prerevealURI;
    }

    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsCommunitySaleActive(bool _isCommunitySaleActive)
        external
        onlyOwner
    {
        isCommunitySaleActive = _isCommunitySaleActive;
    }

    function setCommunityListMerkleRoot(bytes32 _merkleRoot)
        external
        onlyOwner
    {
        communityListMerkleRoot = _merkleRoot;
    }

    function setVerificationHash(string memory _verificationHash)
        external
        onlyOwner
    {
        verificationHash = _verificationHash;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // ============ CHAINLINK FUNCTIONS ============

    function revealNextBatch() public onlyOwner {
        require(
            maxKiftables >= (lastTokenRevealed + REVEAL_BATCH_SIZE),
            "maxKiftables too low"
        );

        COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            3, 
            100000, 
            1 
        );
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        require(
            maxKiftables >= (lastTokenRevealed + REVEAL_BATCH_SIZE),
            "maxKiftables too low"
        );
        setBatchSeed(randomWords[0]);
    }

    // ============ FUNCTION OVERRIDES ============

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
    
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent token");

        if (_tokenId >= lastTokenRevealed) {
            return preRevealBaseURI;
        }

        return
            string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    Strings.toString(getShuffledTokenId(_tokenId)),
                    ".json"
                )
            );
    }

}


contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
