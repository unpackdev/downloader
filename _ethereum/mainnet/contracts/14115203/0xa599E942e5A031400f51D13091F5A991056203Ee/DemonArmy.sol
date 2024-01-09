/*
  _____  ______ __  __  ____  _   _            _____  __  ____     __
 |  __ \|  ____|  \/  |/ __ \| \ | |     /\   |  __ \|  \/  \ \   / /
 | |  | | |__  | \  / | |  | |  \| |    /  \  | |__) | \  / |\ \_/ / 
 | |  | |  __| | |\/| | |  | | . ` |   / /\ \ |  _  /| |\/| | \   /  
 | |__| | |____| |  | | |__| | |\  |  / ____ \| | \ \| |  | |  | |   
 |_____/|______|_|  |_|\____/|_| \_| /_/    \_\_|  \_\_|  |_|  |_|   
                                        
An 0nyX Labs Contract - Development by @White_Oak_Kong
0nyXLabs.io

*/

//SPDX-License-Identifier: MIT

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

interface IDemonYield {
    function updateReward(address _from, address _to) external;

}

contract DemonArmy is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    IDemonYield public DemonYield;
    function setDemonYield(address _demonYield) external onlyOwner { DemonYield = IDemonYield(_demonYield); }

    string private baseURI;
    string public verificationHash;

    uint256 public constant MAX_PER_TXN = 10;
    uint256 public constant MAX_PER_WALLET_PRESALE = 2;
    uint256 public constant MAX_CLAIM = 2;
    uint256 public maxDemons;
    uint256 public royaltyPercentage;

    uint256 public SALE_PRICE = 0.0666 ether;
    uint256 public constant PRE_SALE_PRICE = 0.0666 ether;
    bool public isPublicSaleActive;

    uint256 public maxPreSaleDemons;
    bytes32 public preSaleMerkleRoot;
    bool public isPreSaleActive;

    bytes32 public claimListMerkleRoot;

    mapping(address => uint256) public mintCounts;
    mapping(address => uint256) public claimCounts;

    address FOUNDER_1 = 0x0a9E6c2ff6d86694974914A8363A5B716932bA12;
    address FOUNDER_2 = 0xc4fC810389ccbECcb22c9CE5BB1B4329Ea83525B;
    address FOUNDER_3 = 0x41860033f5014aFFa6EbCE4792390424041468AB;
    address FOUNDER_4 = 0x13489726578C744618c6Dea296AEeE1dcfc205A0;
    address DEV = 0x3B36Cb2c6826349eEC1F717417f47C06cB70b7Ea;
    address CM = 0xB54254Cd85A71Abb6CE9527f9f89e77875d594d9;
    address MARKETING = 0x8C1bf59aFc9A89A941Dafb1eE109B469db507d9e;
    address public COMMUNITY_WALLET = 0x66282e00a1E50A4296ADd8a6DE208da20A8774aD;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier preSaleActive() {
        require(isPreSaleActive, "Presale is not open");
        _;
    }

    modifier canMintDemons(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <= maxDemons,
            "Not enough Demons remaining to mint"
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

        modifier maxTxn(uint256 numberOfTokens) {
        require(
            numberOfTokens <= MAX_PER_TXN,
            "Max Demons to mint is three"
        );
        _;
    }


    constructor(
        uint256 _maxDemons,
        uint256 _maxPreSaleDemons
    ) ERC721("DEMONS", "DEMONS") {
        maxDemons = _maxDemons;
        maxPreSaleDemons = _maxPreSaleDemons;
    }

    // ---  PUBLIC MINTING FUNCTIONS ---

    // mint allows for regular minting while the supply does not exceed maxDemons.
    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(SALE_PRICE, numberOfTokens)
        publicSaleActive
        canMintDemons(numberOfTokens)
        maxTxn(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // mintPreSale allows for minting by allowed addresses during the pre-sale.
    function mintPreSale(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleActive
        canMintDemons(numberOfTokens)
        isCorrectPayment(PRE_SALE_PRICE, numberOfTokens)
        isValidMerkleProof(merkleProof, preSaleMerkleRoot)
    {
        uint256 numAlreadyMinted = mintCounts[msg.sender];

        require(
            numAlreadyMinted + numberOfTokens <= MAX_PER_WALLET_PRESALE,
            "Max Demons to mint in Presale is two"
        );

        require(
            tokenCounter.current() + numberOfTokens <= maxPreSaleDemons,
            "Not enough Demons remaining to mint"
        );

        mintCounts[msg.sender] = numAlreadyMinted + numberOfTokens;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // claim allows for free claim of two demons.
    function claim(bytes32[] calldata merkleProof)
        external
        nonReentrant
        canMintDemons(2)
        isValidMerkleProof(merkleProof, claimListMerkleRoot)
    {
        uint256 numAlreadyClaimed = claimCounts[msg.sender];

        require(
            numAlreadyClaimed + 2 <= MAX_CLAIM,
            "Max Demons to claim is two."
        );

        require(
            tokenCounter.current() + 2 <= maxPreSaleDemons,
            "Not enough Demons remaining to mint"
        );

        claimCounts[msg.sender] = numAlreadyClaimed + 2;
            _safeMint(msg.sender, nextTokenId());
            _safeMint(msg.sender, nextTokenId());
            
    }


    // -- OWNER ONLY MINT --
    function ownerMint(uint256 numberOfTokens)
        external
        nonReentrant
        onlyOwner
        canMintDemons(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    // --- READ-ONLY FUNCTIONS ---

    // getBaseURI returns the baseURI hash for collection metadata.
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    // getLastTokenId returns the last tokenId minted.
    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // -- ADMIN FUNCTIONS --

    // setBaseURI sets the base URI for token metadata.
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // capSupply is an emergency function to reduce the maximum supply of Demons.
    function capSupply(uint256 _supply) external onlyOwner {
        require(_supply > tokenCounter.current(), "cannot reduce maximum supply below current count.");
        require(_supply > maxDemons, "cannot increase the maximum supply.");
        maxDemons = _supply;
    }

    // updatePrice is an emergency function to adjust the price of Demons.
    function updatePrice(uint256 _price) external onlyOwner {
        SALE_PRICE = _price;
    } 

    // updatePrice is function to adjust the address of the community wallet.
    function updateCommunityWallet(address _communityWallet) external onlyOwner {
        COMMUNITY_WALLET = _communityWallet;
    } 

    function setVerificationHash(string memory _verificationHash)
        external
        onlyOwner
    {
        verificationHash = _verificationHash;
    }

    // setIsPublicSaleActive toggles the functionality of the public minting function.
    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setRoyaltyAmount(uint256 _royaltyPercentage) external onlyOwner {
        royaltyPercentage = _royaltyPercentage;
    }

    // setIsPreSaleActive toggles the functionality of the presale minting function.
    function setIsPreSaleActive(bool _isPreSaleActive)
        external
        onlyOwner
    {
        isPreSaleActive = _isPreSaleActive;
    }

    // setPresaleListMerkleRoot sets the merkle root for presale allowed addresses.
    function setPresaleListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        preSaleMerkleRoot = merkleRoot;
    }

    // setClaimListMerkleRoot sets the merkle root for free claim addresses.
    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    // withdraw allows for the withdraw of all ETH to the assigned wallets.
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(FOUNDER_1, (balance * 20) / 100);
        _withdraw(FOUNDER_2, (balance * 20) / 100);
        _withdraw(FOUNDER_3, (balance * 20) / 100);
        _withdraw(FOUNDER_4, (balance * 5) / 100);
        _withdraw(DEV, (balance * 10) / 100);
        _withdraw(COMMUNITY_WALLET, (balance * 10) / 100);
        _withdraw(CM, (balance * 10) / 100);
        _withdraw(MARKETING, (balance * 5) / 100);
        
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // nextTokenId collects the next tokenId to mint.
    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

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

    // Custom Transfer Hook override ERC721 and update yield reward.
    function transferFrom(address from, address to, uint256 tokenId) public override {
        DemonYield.updateReward(from, to);
        ERC721.transferFrom(from, to, tokenId);
    }
    // Custom Transfer Hook override ERC721 and update yield reward.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        DemonYield.updateReward(from, to);
        ERC721.safeTransferFrom(from, to, tokenId, data);
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
            string(abi.encodePacked(baseURI, "/", tokenId.toString()));
    }
    
    /**
     * Override royalty % for future application.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, royaltyPercentage), 100));
    }
}