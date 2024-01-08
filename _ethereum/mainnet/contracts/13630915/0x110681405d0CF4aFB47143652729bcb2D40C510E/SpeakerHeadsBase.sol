// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

interface IOGGenesis is IERC721 {
    function totalSupply() external view returns (uint256);
}

contract SpeakerHeadsBase is ERC721, Ownable, ReentrancyGuard {
    using Address for address;

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant BRAND_RESERVED = 1; // [no. 0] reserved for the brand
    uint256 public constant SPECIAL_EDITIONS_RESERVED = 8; // [no. 1-8] reserved non-random special editions
    uint256 public constant CORE_RESERVED = 79; // [no. 9-87] reserved for charity, education, advisors, and giveaway
    uint256 public constant OG_BONUS_TRAIT_RESERVED = 103; // Reserved for OG holders bonus Vol 1 tokens

    uint256 internal _tokenIds;
    uint256 internal _mintPrice = 0.06 ether;
    uint256 internal _maxMint = 10;
    address internal _teamAddress;

    IOGGenesis private immutable _ogContract;

    bool public preminted = false;
    bool public saleActive = false;

    constructor(address teamAddress, address ogContractAddress)
        ERC721("SpeakerHeads Vol. 1", "SPKR1")
    {
        _teamAddress = teamAddress;
        _ogContract = IOGGenesis(ogContractAddress);
    }

    function premint() public onlyOwner {
        require(!preminted, "Already preminted brand reserve");
        _mintAmount(BRAND_RESERVED, _teamAddress);
        _mintAmount(SPECIAL_EDITIONS_RESERVED, _teamAddress);
        _mintAmount(CORE_RESERVED, _teamAddress);
        _mintAmount(OG_BONUS_TRAIT_RESERVED, _teamAddress);

        // Airdrop to 0G holders (who aren't us)
        uint256 numOGMinted = _ogContract.totalSupply();
        address teamAddress = _teamAddress;
        for (uint256 i = 0; i < numOGMinted; i++) {
            address owner = _ogContract.ownerOf(i);
            if (owner != teamAddress) {
                _mintAmount(1, owner);
            }
        }
        preminted = true;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds;
    }

    function toggleSaleActive() public onlyOwner {
        saleActive = !saleActive;
    }

    function publicMint(uint256 amount)
        public
        payable
        isPremintComplete
        nonReentrant
        isSaleActive
        isNotContract
        isValidPayment(amount)
        validPublicTxLimit(amount)
    {
        _mintAmount(amount, msg.sender);
    }

    function _mintAmount(uint256 amount, address to)
        internal
        tokensAvailable(amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, totalSupply());
            _tokenIds += 1;
        }
    }

    function ownerMint(uint256 amount) public onlyOwner {
        _mintAmount(amount, msg.sender);
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _mintPrice = _newPrice;
    }

    function setMaxMint(uint256 _newMaxMint) public onlyOwner {
        _maxMint = _newMaxMint;
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

    function withdraw() public onlyOwner {
        withdrawTo(address(0), 0);
    }

    function _numSpecialEditionToken() internal pure returns (uint256) {
        return (SPECIAL_EDITIONS_RESERVED + BRAND_RESERVED);
    }

    modifier isSaleActive() {
        require(saleActive, "Sale it not active");
        _;
    }

    modifier isPremintComplete() {
        require(preminted, "Must premint first");
        _;
    }

    modifier validPublicTxLimit(uint256 amount) {
        require(amount > 0, "Must specify amount");
        require(amount <= _maxMint, "Exceeds the maximum amount");
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
        require(msg.value == _mintPrice * amount, "Invalid Ether amount sent");
        _;
    }

    // Let's at least avoid a thesevens situation
    // https://etherscan.io/tx/0x9bbef2282c33ca564b1e58505193fc737e7c5a326ef14aec25da199af2a4dc51
    modifier isNotContract() {
        require(msg.sender == tx.origin, "Proxies cannot mint");
        _;
    }
}
