// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./ECDSA.sol";

import "./console.sol";

contract BullTime is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    enum MintStatus {
        CLOSED,
        GENESIS,
        PRESALE,
        PUBLIC
    }

    string private _baseTokenURI;
    string internal _unrevealedURI;

    uint256 public constant MAX_SUPPLY = 3433;

    uint256 public constant GIFT_LIMIT = 100;
    uint256 public constant GENESIS_LIMIT = 100;
    uint256 public constant PRESALE_LIMIT = 2000;

    uint256 public constant GENESIS_PER_ADDRESS = 1;
    uint256 public constant GIFT_PER_ADDRESS = 1;
    // presale and public sale per address limitation
    uint256 public constant SALE_PER_ADDRESS = 3;

    uint256 public constant GENESIS_PRICE = 0.19 ether;
    uint256 public constant PRESALE_PRICE = 0.088 ether;
    uint256 public constant PUBLIC_PRICE = 0.098 ether;

    mapping(address => bool) public giftedList;

    mapping(address => bool) public genesisList;
    mapping(address => uint256) public genesisListPurchases;

    mapping(address => bool) public presaleList;
    mapping(address => uint256) public presaleListPurchases;

    mapping(address => uint256) public publicListPurchases;

    uint256 public giftedAmount;

    uint256 public genesisAmountMinted;
    uint256 public preSaleAmountMinted;
    uint256 public publicAmountMinted;

    bool public revealed;

    MintStatus public mintStatus = MintStatus.CLOSED;

    address private Kaddr = 0x8C03484009250Ea8a44CC0190ACbbdD6b7c7124e; // 5%
    address private Daddr = 0x0e9C942b21e173FE16EbF196D04C37ac37312f21; // 5%
    address private Laddr = 0x0F2Cc53B44DCAA0618772df7F75e8e979885b192; // 5%
    address private Taddr = 0x01F40ca319868e5c3eAE40C53d1962B22F8F9fAC; // 5%
    address private DAaddr = 0xc790E747F6E333c9845143A1e823f6013e36293f; // 5%
    address private Zaddr = 0x0cA9128306B869fb405D29800B397D2829016c04; // 14%
    address private Caddr = 0xb54Ca7687eF3E6FdE424c797C968b47b9fC408f4; // 1.5%
    address private Iaddr = 0xfa11b64407Cda9bD62EB8264aD7D888927A65cf4; // 0.5%
    address private Aaddr = 0x1D37BB037c057D452B6903F8F661C7eA4E13a145; // 0.5%

    constructor(
        string memory hiddenUri
    ) ERC721A("Bull Time", "BULL_TIME") {
        _unrevealedURI = hiddenUri;
    }

    modifier canBuy(uint256 quantity) {
        require(quantity >= 0, "WRONG_QUANTITY");
        require(mintStatus != MintStatus.CLOSED, "CONTRACT_LOCKED");
        require(totalMinted() + quantity <= MAX_SUPPLY, "TOKENS_EXPIRED");

        // check restrictions
        require(walletWhitelisted(msg.sender), "NOT_WHITELISTED");
        require(!walletPerLimitExpired(msg.sender, quantity), "EXPIRED_PER_WALLET_TRANSACTION");
        require(!supplyLimitExpired(quantity), "SUPPLY_LIMIT_EXPIRED");

        uint256 price = activePrice();
        require(msg.value >= price * quantity, "INSUFFICIENT_VALUE");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _addToList(address[] calldata entries, mapping(address => bool) storage list) private {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!list[entry], "DUPLICATE_ENTRY");
            list[entry] = true;
        }
    }

    function _removeFromList(address[] calldata entries, mapping(address => bool) storage list) private {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            list[entry] = false;
        }
    }

    // --- gift
    function freeMint(uint256 quantity) external {
        require(giftedList[msg.sender], "NOT_WHITELISTED");
        require(quantity <= GIFT_PER_ADDRESS, "ONLY_ONE_GIFT");
        require(giftedAmount + quantity <= GIFT_LIMIT, "SUPPLY_LIMIT_EXPIRED");
        require(totalMinted() + quantity <= MAX_SUPPLY, "TOKENS_EXPIRED");

        giftedAmount += quantity;

        delete giftedList[msg.sender];

        _safeMint(msg.sender, quantity);
    }

    function addToGiftList(address[] calldata entries) external onlyOwner {
        _addToList(entries, giftedList);
    }

    function removeFromGiftList(address[] calldata entries) external onlyOwner {
        _removeFromList(entries, giftedList);
    }

    // --- genesis
    function genesisMint(uint256 quantity) external payable canBuy(quantity) {
        genesisAmountMinted += quantity;
        genesisListPurchases[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function addToGenesisList(address[] calldata entries) external onlyOwner {
        _addToList(entries, genesisList);
    }

    function removeFromGenesisList(address[] calldata entries) external onlyOwner {
        _removeFromList(entries, genesisList);
    }

    // --- presale
    function preSaleMint(uint256 quantity) external payable canBuy(quantity) {
        preSaleAmountMinted += quantity;
        presaleListPurchases[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    function addToPresaleList(address[] calldata entries) external onlyOwner {
        _addToList(entries, presaleList);
    }

    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        _removeFromList(entries, presaleList);
    }

    // --- public mint
    function publicMint(uint256 quantity) external payable canBuy(quantity) {
        publicAmountMinted += quantity;
        publicListPurchases[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    // erc721 and ownable specific
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setUnrevealedURI(string calldata unrevealedURI) external onlyOwner {
        _unrevealedURI = unrevealedURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!revealed) {
            return _unrevealedURI;
        }

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        uint256 fivePercent = balance * 5 / 100;

        payable(Kaddr).transfer(fivePercent);
        payable(Daddr).transfer(fivePercent);
        payable(Laddr).transfer(fivePercent);
        payable(Taddr).transfer(fivePercent);
        payable(DAaddr).transfer(fivePercent);

        payable(Zaddr).transfer(balance * 14 / 100);
        payable(Caddr).transfer(balance * 15 / 1000);
        payable(Iaddr).transfer(fivePercent / 10);
        payable(Aaddr).transfer(fivePercent / 10);

        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawGenesis() external onlyOwner nonReentrant {
        payable(msg.sender).transfer(address(this).balance);
    }

    function closeContract() external onlyOwner {
        mintStatus = MintStatus.CLOSED;
    }

    function enableGenesisMint() external onlyOwner {
        mintStatus = MintStatus.GENESIS;
    }

    function enablePresaleMint() external onlyOwner {
        mintStatus = MintStatus.PRESALE;
    }

    function enablePublicMint() external onlyOwner {
        mintStatus = MintStatus.PUBLIC;
    }
    // helpers
    function genesisActive() public view returns (bool) {
        return mintStatus == MintStatus.GENESIS;
    }

    function preSaleActive() public view returns (bool) {
        return mintStatus == MintStatus.PRESALE;
    }

    function publicSaleActive() public view returns (bool) {
        return mintStatus == MintStatus.PUBLIC;
    }

    function activePrice() public view returns (uint256) {
        return genesisActive() ? GENESIS_PRICE
        : preSaleActive()
        ? PRESALE_PRICE : PUBLIC_PRICE;
    }

    function walletWhitelisted(address sender) public view returns (bool) {
        return genesisActive() ? genesisList[sender] : preSaleActive() ? presaleList[sender] : true;
    }

    function walletPerLimitExpired(address sender, uint256 number) public view returns (bool) {
        uint256 addressLimit = genesisActive() ? GENESIS_PER_ADDRESS : SALE_PER_ADDRESS;
        mapping(address => uint256) storage purchaseList = genesisActive()
        ? genesisListPurchases : preSaleActive()
        ? presaleListPurchases : publicListPurchases;

        return purchaseList[sender] + number > addressLimit;
    }

    function supplyLimitExpired(uint256 number) public view returns (bool) {
        uint256 supplyLimit = genesisActive() ? GENESIS_LIMIT
        : preSaleActive()
        ? PRESALE_LIMIT : MAX_SUPPLY;

        uint256 mintAmount = genesisActive() ? genesisAmountMinted
        : preSaleActive()
        ? preSaleAmountMinted : publicAmountMinted;

        return mintAmount + number > supplyLimit;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }
}
