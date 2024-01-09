//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.0;


import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract HAYC is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI;
    string public verificationHash;

    uint256 public constant MAX_HAYC_PER_WALLET = 5;
    uint256 public maxHAYC;

    uint256 public constant PUBLIC_SALE_PRICE = 0.1 ether;
    bool public isPublicSaleActive;

    uint256 public constant COMMUNITY_SALE_PRICE = 0.07 ether;
    uint256 public maxCommunitySaleHAYC;
    bytes32 public communitySaleMerkleRoot;
    bool public isCommunitySaleActive;

    uint256 public maxGiftedHAYC;
    uint256 public numGiftedHAYC;
    bytes32 public claimListMerkleRoot;

    mapping(address => uint256) public communityMintCounts;
    mapping(address => bool) public claimed;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier communitySaleActive() {
        require(isCommunitySaleActive, "Community sale is not open");
        _;
    }

    modifier maxHAYCPerWallet(uint256 numberOfTokens) {
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_HAYC_PER_WALLET,
            "Max HAYC to mint is three"
        );
        _;
    }

    modifier canMintHAYC(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxHAYC - maxGiftedHAYC,
            "Not enough HAYC remaining to mint"
        );
        _;
    }

    modifier canGiftHAYC(uint256 num) {
        require(
            numGiftedHAYC + num <= maxGiftedHAYC,
            "Not enough HAYC remaining to gift"
        );
        require(
            tokenCounter.current() + num <= maxHAYC,
            "Not enough HAYC remaining to mint"
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
            "Address does not exist in list"
        );
        _;
    }

    constructor(
        uint256 _maxHAYC,
        uint256 _maxCommunitySaleHAYC,
        uint256 _maxGiftedHAYC
    ) ERC721("Hightech Ape Yacht Club", "HAYC") {
        maxHAYC = _maxHAYC;
        maxCommunitySaleHAYC = _maxCommunitySaleHAYC;
        maxGiftedHAYC = _maxGiftedHAYC;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        publicSaleActive
        canMintHAYC(numberOfTokens)
        maxHAYCPerWallet(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }


    function mintCommunitySale(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof
    )
        external
        payable
        nonReentrant
        communitySaleActive
        canMintHAYC(numberOfTokens)
        isCorrectPayment(COMMUNITY_SALE_PRICE, numberOfTokens)
        isValidMerkleProof(merkleProof, communitySaleMerkleRoot)
    {
        uint256 numAlreadyMinted = communityMintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_HAYC_PER_WALLET,
            "Max HAYC to mint in community sale is three"
        );

        require(
            tokenCounter.current() + numberOfTokens <= maxCommunitySaleHAYC,
            "Not enough HAYC remaining to mint"
        );

        communityMintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function claim(bytes32[] calldata merkleProof)
        external
        isValidMerkleProof(merkleProof, claimListMerkleRoot)
        canGiftHAYC(1)
    {
        require(!claimed[msg.sender], "Witch already claimed by this wallet");

        claimed[msg.sender] = true;
        numGiftedHAYC += 1;

        _safeMint(msg.sender, nextTokenId());
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setVerificationHash(string memory _verificationHash)
        external
        onlyOwner
    {
        verificationHash = _verificationHash;
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


    function setCommunityListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        communitySaleMerkleRoot = merkleRoot;
    }


    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    function reserveForGifting(uint256 numToReserve)
        external
        nonReentrant
        onlyOwner
        canGiftHAYC(numToReserve)
    {
        numGiftedHAYC += numToReserve;

        for (uint256 i = 0; i < numToReserve; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }


    function giftHAYC(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canGiftHAYC(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGiftedHAYC += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], nextTokenId());
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function rollOverHAYC(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
    {
        require(
            tokenCounter.current() + addresses.length <= 128,
            "All HAYC are already rolled over"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            communityMintCounts[addresses[i]] += 1;
            // use mint rather than _safeMint here to reduce gas costs
            // and prevent this from failing in case of grief attempts
            _mint(addresses[i], nextTokenId());
        }
    }

    // ============ SUPPORTING FUNCTIONS ============

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
    }
}