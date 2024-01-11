//SPDX-License-Identifier: MIT

//  _____ ______   _______  _________  ________  ________  ___  ___  ________  ________
// |\   _ \  _   \|\  ___ \|\___   ___\\   __  \|\   __  \|\  \|\  \|\   ____\|\   ____\
// \ \  \\\__\ \  \ \   __/\|___ \  \_\ \  \|\  \ \  \|\  \ \  \\\  \ \  \___|\ \  \___|_
//  \ \  \\|__| \  \ \  \_|/__  \ \  \ \ \   __  \ \   ____\ \  \\\  \ \  \  __\ \_____  \
//   \ \  \    \ \  \ \  \_|\ \  \ \  \ \ \  \ \  \ \  \___|\ \  \\\  \ \  \|\  \|____|\  \
//    \ \__\    \ \__\ \_______\  \ \__\ \ \__\ \__\ \__\    \ \_______\ \_______\____\_\  \
//     \|__|     \|__|\|_______|   \|__|  \|__|\|__|\|__|     \|_______|\|_______|\_________\
//                                                                               \|_________|

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract Metapugs is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    string private baseURI;
    string public provenanceHash;
    address private openSeaProxyRegistryAddress;

    bool private isOpenSeaProxyActive = true;
    bool public isPresaleActive;
    bool public isPublicSaleActive;

    uint256 private primaryPercentage = 85;
    uint256 private secondaryPercentage = 13;
    uint256 public publicSaleLimit = 10;
    uint256 public presaleLimit = 5;
    uint256 public publicSalePrice = 0.065 ether;
    uint256 public presalePrice = 0.065 ether;
    uint256 public maxTokens;
    uint256 public maxPresaleTokens;
    uint256 public maxGiftedTokens;
    uint256 public numGiftedTokens;

    address primaryAddress;
    address secondaryAddress;
    address tertiaryAddress;

    bytes32 public presaleMerkleRoot;
    bytes32 public giftMerkleRoot;

    mapping(address => uint256) public presaleMintCount;
    mapping(address => bool) public gifted;

    // ACCESS CONTROL/SANITY MODIFIERS

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not active");
        _;
    }

    modifier presaleActive() {
        require(isPresaleActive, "Presale sale is not active");
        _;
    }

    modifier maxTokensPerTransaction(uint256 numberOfTokens) {
        require(
            numberOfTokens <= publicSaleLimit,
            "Quantity exceeds public sale limit for a transaction"
        );
        _;
    }

    modifier canMintTokens(uint256 numberOfTokens) {
        require(
            tokenCounter.current() + numberOfTokens <=
                maxTokens - maxGiftedTokens,
            "Not enough tokens remaining to mint"
        );
        _;
    }

    /**
     * @dev checks if the payment is correct
     */
    modifier canGiftTokens(uint256 num) {
        require(
            numGiftedTokens + num <= maxGiftedTokens,
            "Not enough tokens remaining to gift"
        );
        require(
            tokenCounter.current() + num <= maxTokens,
            "Not enough tokens remaining to mint"
        );
        _;
    }

    /**
     * @dev checks if the payment is correct
     */
    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address not found on list"
        );
        _;
    }

    constructor(
        address _openSeaProxyRegistryAddress,
        address _primaryAddress,
        address _secondaryAddress,
        address _tertiaryAddress,
        uint256 _maxTokens,
        uint256 _maxPresaleTokens,
        uint256 _maxGiftedTokens
    ) ERC721("Metapugs", "METP") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        primaryAddress = _primaryAddress;
        secondaryAddress = _secondaryAddress;
        tertiaryAddress = _tertiaryAddress;
        maxTokens = _maxTokens;
        maxPresaleTokens = _maxPresaleTokens;
        maxGiftedTokens = _maxGiftedTokens;
    }

    receive() external payable {}

    // PUBLIC FUNCTIONS FOR MINTING

    function mint(uint256 numberOfTokens)
        external
        payable
        nonReentrant
        isCorrectPayment(publicSalePrice, numberOfTokens)
        publicSaleActive
        canMintTokens(numberOfTokens)
        maxTokensPerTransaction(numberOfTokens)
    {
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function mintPresale(uint8 numberOfTokens, bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        presaleActive
        canMintTokens(numberOfTokens)
        isCorrectPayment(presalePrice, numberOfTokens)
        isValidMerkleProof(merkleProof, presaleMerkleRoot)
    {
        uint256 numAlreadyMinted = presaleMintCount[msg.sender];
        uint256 total = numAlreadyMinted + numberOfTokens;

        require(
            total <= presaleLimit,
            "Quantity exceeds presale limit for this wallet"
        );

        require(
            tokenCounter.current() + numberOfTokens <= maxPresaleTokens,
            "Not enough tokens remaining to mint"
        );

        presaleMintCount[msg.sender] = total;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, nextTokenId());
        }
    }

    function gift(bytes32[] calldata merkleProof)
        external
        isValidMerkleProof(merkleProof, giftMerkleRoot)
        canGiftTokens(1)
    {
        require(!gifted[msg.sender], "Token already gifted to this address");

        gifted[msg.sender] = true;
        numGiftedTokens += 1;

        _safeMint(msg.sender, nextTokenId());
    }

    // PUBLIC READ-ONLY FUNCTIONS

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // OWNER-ONLY ADMIN FUNCTIONS

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function setProvenanceHash(string memory _provenanceHash)
        external
        onlyOwner
    {
        provenanceHash = _provenanceHash;
    }

    function togglePresale() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function togglePublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function setPresaleMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        presaleMerkleRoot = merkleRoot;
    }

    function setGiftMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        giftMerkleRoot = merkleRoot;
    }

    function setPublicSalePrice(uint256 price) external onlyOwner {
        publicSalePrice = price;
    }

    function setPresalePrice(uint256 price) external onlyOwner {
        presalePrice = price;
    }

    function setPresaleLimit(uint256 limit) external onlyOwner {
        presaleLimit = limit;
    }

    function setPublicSaleLimit(uint256 limit) external onlyOwner {
        publicSaleLimit = limit;
    }

    function adminMint(uint256 numToMint, address to)
        external
        nonReentrant
        onlyOwner
        canGiftTokens(numToMint)
    {
        numGiftedTokens += numToMint;

        for (uint256 i = 0; i < numToMint; i++) {
            _safeMint(to, nextTokenId());
        }
    }

    function giftTokens(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
        canGiftTokens(addresses.length)
    {
        uint256 numToGift = addresses.length;
        numGiftedTokens += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            _safeMint(addresses[i], nextTokenId());
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance cannot be zero");
        uint256 balanceForPrimary;
        uint256 balanceForSecondary;
        uint256 remainder = balance;
        bool success;

        balanceForPrimary = (balance * primaryPercentage) / 100;
        remainder -= balanceForPrimary;

        balanceForSecondary = (balance * secondaryPercentage) / 100;
        remainder -= balanceForSecondary;

        (success, ) = primaryAddress.call{value: balanceForPrimary}("");
        require(success, "Transfer failed");

        (success, ) = secondaryAddress.call{value: balanceForSecondary}("");
        require(success, "Transfer failed");

        (success, ) = tertiaryAddress.call{value: remainder}("");
        require(success, "Transfer failed");
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function rollOverTokens(address[] calldata addresses)
        external
        nonReentrant
        onlyOwner
    {
        require(
            tokenCounter.current() + addresses.length <= 128,
            "All tokens are already rolled over"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            presaleMintCount[addresses[i]] += 1;
            _mint(addresses[i], nextTokenId());
        }
    }

    // SUPPORTING FUNCTIONS

    function nextTokenId() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // FUNCTION OVERRIDES

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
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
}

/**
 * @dev These contract definitions are used to create a reference to the OpenSea
 *  ProxyRegistry contract by using the registry's address (see isApprovedForAll).
 */
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}