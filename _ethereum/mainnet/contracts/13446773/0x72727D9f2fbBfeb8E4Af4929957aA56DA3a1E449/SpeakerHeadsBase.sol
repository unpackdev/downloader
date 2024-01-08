// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Whitelisted.sol";

contract SpeakerHeadsBase is ERC721, Ownable, Whitelisted, ReentrancyGuard {
    using Address for address;
    using ECDSA for bytes32;

    uint256 public constant MINT_PRICE = 0.12 ether;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant PUBLIC_MAX_MINT = 10;
    uint256 public constant WHITELIST_MAX_MINT = 3;
    uint256 public constant BRAND_RESERVED = 1; // [no. 0] reserved for the brand
    uint256 public constant SPECIAL_EDITIONS_RESERVED = 8; // [no. 1-8] reserved non-random special editions
    uint256 public constant CORE_RESERVED = 91; // [no. 9-99] reserved for charity, education, advisors, and giveaway

    uint256 internal _tokenIds;

    address internal _teamAddress;

    mapping(address => uint256) internal _numberWhitelistMinted;

    bool public whitelistSaleActive = false;
    bool public saleActive = false;

    bool public brandPreminted = false;
    bool public specialEditionsPreminted = false;
    bool public corePreminted = false;

    constructor(address teamAddress, address signer)
        ERC721("SpeakerHeads Volume 1", "SPKR")
        Whitelisted(signer)
    {
        _teamAddress = teamAddress;
    }

    function premintBrandReserve() public onlyOwner {
        require(!brandPreminted, "Already preminted token 0");
        _safeMint(_teamAddress, totalSupply());
        _tokenIds += 1;
        brandPreminted = true;
    }

    function premintSpecialEditions() public onlyOwner {
        require(!specialEditionsPreminted, "Special editions already minted");
        require(brandPreminted, "Must premint brand token first");

        for (uint256 i = 0; i < SPECIAL_EDITIONS_RESERVED; i++) {
            _safeMint(_teamAddress, totalSupply());
            _tokenIds += 1;
        }
        specialEditionsPreminted = true;
    }

    function premintCoreReserve() public onlyOwner {
        require(!corePreminted, "Core reserve already minted");
        require(brandPreminted, "Must premint brand token first");
        require(specialEditionsPreminted, "Premint special editions first");

        for (uint256 i = 0; i < CORE_RESERVED; i++) {
            _safeMint(_teamAddress, totalSupply());
            _tokenIds += 1;
        }
        corePreminted = true;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds;
    }

    function toggleWhitelistSaleActive() public onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }

    function toggleSaleActive() public onlyOwner {
        saleActive = !saleActive;
    }

    function whitelistMint(bytes memory signature, uint256 amount)
        public
        payable
        isPremintComplete
        nonReentrant
        isWhitelistSaleActive
        isValidWhitelistSignature(signature)
        hasRemainingWhitelistMints(amount)
    {
        _mintAmount(amount, msg.sender);
        _numberWhitelistMinted[msg.sender] += amount;
    }

    function usedWhitelistMints()
        public
        view
        isWhitelistSaleActive
        returns (uint256)
    {
        return _numberWhitelistMinted[msg.sender];
    }

    function publicMint(uint256 amount)
        public
        payable
        isPremintComplete
        nonReentrant
        isSaleActive
        validPublicTxLimit(amount)
    {
        _mintAmount(amount, msg.sender);
    }

    function _mintAmount(uint256 amount, address to)
        internal
        isNotContract
        tokensAvailable(amount)
        isValidPayment(amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalSupply());
            _tokenIds += 1;
        }
    }

    function withdrawTo(address to, uint256 amount) public onlyOwner {
        if (to == address(0)) {
            to = msg.sender;
        }
        if (amount == 0) {
            amount = address(this).balance;
        }
        require(payable(to).send(amount), "Address cannot receive payment");
    }

    function _numSpecialEditionToken() internal pure returns (uint256) {
        return (SPECIAL_EDITIONS_RESERVED + BRAND_RESERVED);
    }

    modifier isSaleActive() {
        require(saleActive, "Sale it not active");
        _;
    }

    modifier isWhitelistSaleActive() {
        require(whitelistSaleActive, "Presale is not active");
        _;
    }

    modifier isPremintComplete() {
        require(
            brandPreminted && specialEditionsPreminted && corePreminted,
            "Must premint first"
        );
        _;
    }

    modifier hasRemainingWhitelistMints(uint256 amount) {
        require(amount > 0, "Must specify amount");
        require(
            _numberWhitelistMinted[msg.sender] + amount <= WHITELIST_MAX_MINT,
            "Exceeds whitelist allowance"
        );
        _;
    }

    modifier validPublicTxLimit(uint256 amount) {
        require(amount > 0, "Must specify amount");
        require(amount <= PUBLIC_MAX_MINT, "Exceeds the maximum amount");
        _;
    }

    modifier tokensAvailable(uint256 amount) {
        require(
            (totalSupply() + amount) <= MAX_SUPPLY,
            "Exceeds maximum number of tokens"
        );
        _;
    }

    modifier isValidPayment(uint256 amount) {
        require(msg.value == MINT_PRICE * amount, "Invalid Ether amount sent");
        _;
    }

    // Let's at least avoid a thesevens situation
    // https://etherscan.io/tx/0x9bbef2282c33ca564b1e58505193fc737e7c5a326ef14aec25da199af2a4dc51
    modifier isNotContract() {
        require(msg.sender == tx.origin, "Proxies cannot mint");
        _;
    }
}
