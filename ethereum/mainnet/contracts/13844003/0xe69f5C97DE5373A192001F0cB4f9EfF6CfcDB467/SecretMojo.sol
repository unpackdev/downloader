//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SecretMojo is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenIdCounter;

    enum State {PENDING, AVAILABLE, PAID, FREE, PAUSED, PRE_REVEALED, REVEALED}

    State public state = State.PENDING;
    uint32 public maxSupply;

    uint256 public paidSupplyLimit = 4000;
    uint256 public paidMintCount;
    //0.05 eth
    uint256 public tokenPrice = 50_000_000_000_000_000;
    uint8 public maxMintPerTx = 10;
    uint8 public secretARange = 0;
    uint8 public secretBRange = 0;
    uint8 public secretAShifter = 0;
    uint8 public secretBShifter = 0;

    mapping(uint256 => bool) public freeTokens;
    mapping(address => uint8) public freeTokenQuota;

    mapping(uint256 => uint8) public secretAOverride;
    mapping(uint256 => uint8) public secretBOverride;


    string public baseURI;
    string public defaultUrl;

    constructor(string memory name_, string memory symbol_, uint32 maxSupply_, string memory baseURI_, string memory defaultUrl_)  ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
        baseURI = baseURI_;
        defaultUrl = defaultUrl_;
    }

    function freeMint() external {
        require(state == State.FREE || state == State.AVAILABLE, "Wrong state for freeMint");
        freeTokenQuota[msg.sender] -= 1;

        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        freeTokens[tokenId] = true;
        _mint(msg.sender, tokenId);

    }

    function mint() external payable {
        require(state == State.PAID || state == State.AVAILABLE, "Wrong state for mint");
        require(paidMintCount < paidSupplyLimit, "paidSupplyLimit reached");
        require(msg.value == tokenPrice, "Insufficient funds");
        paidMintCount += 1;

        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        _mint(msg.sender, tokenId);

    }

    function freeMintBatch(uint8 quantity) external {
        require(state == State.FREE || state == State.AVAILABLE, "Wrong state for freeMint");

        freeTokenQuota[msg.sender] -= quantity;

        for (uint i = 0; i < quantity; i++) {
            tokenIdCounter.increment();
            uint256 tokenId = tokenIdCounter.current();
            freeTokens[tokenId] = true;
            _mint(msg.sender, tokenId);
        }

    }


    function mintBatch(uint8 quantity) external payable {
        require(state == State.PAID || state == State.AVAILABLE, "Wrong state for mint");
        require(quantity <= maxMintPerTx, "maxMintPerTx can not be exceed.");
        require(paidMintCount + quantity <= paidSupplyLimit, "paidSupplyLimit reached");
        uint256 cost = quantity * tokenPrice;
        require(msg.value == cost, "Insufficient funds");
        paidMintCount += quantity;

        for (uint i = 0; i < quantity; i++) {
            tokenIdCounter.increment();
            uint256 tokenId = tokenIdCounter.current();
            _mint(msg.sender, tokenId);
        }
    }

    function _mint(address to, uint256 tokenId) internal override {
        require(tokenId <= maxSupply, "Can not exceed maxSupply");
        ERC721._mint(to, tokenId);
    }

    function setState(State state_) external onlyOwner() {
        state = state_;
        if (state == State.PRE_REVEALED && secretAShifter == 0 ) {
            secretAShifter = uint8(uint256(keccak256(abi.encodePacked(tokenIdCounter.current(), blockhash(block.number), block.difficulty))) % secretARange + 1);
            secretBShifter = uint8(uint256(keccak256(abi.encodePacked(tokenIdCounter.current(), blockhash(block.number), block.difficulty))) % secretBRange + 1);
        }
    }

    function setTokenPrice(uint256 tokenPrice_) external onlyOwner() {
        tokenPrice = tokenPrice_;
    }

    function setPaidSupplyLimit(uint256 paidSupplyLimit_) external onlyOwner() {
        paidSupplyLimit = paidSupplyLimit_;
    }

    function setMaxSupply(uint32 maxSupply_) external onlyOwner() {
        maxSupply = maxSupply_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        baseURI = baseURI_;
    }

    function setDefaultUrl(string memory defaultUrl_) external onlyOwner() {
        defaultUrl = defaultUrl_;
    }

    function setSecretARange(uint8 secretARange_) external onlyOwner() {
        secretARange = secretARange_;
    }

    function setSecretBRange(uint8 secretBRange_) external onlyOwner() {
        secretBRange = secretBRange_;
    }

    function setMaxMintPerTx(uint8 maxMintPerTx_) external onlyOwner() {
        maxMintPerTx = maxMintPerTx_;
    }

    function addFreeTokenQuota(address[] calldata addresses, uint8 quota) external onlyOwner() {
        for (uint i = 0; i < addresses.length; i++) {
            freeTokenQuota[addresses[i]] = quota;
        }
    }

    function overrideTokenSecretA(uint256 tokenId, uint8 newValue) external onlyOwner() {
        secretAOverride[tokenId] = newValue;
    }

    function overrideTokenSecretB(uint256 tokenId, uint8 newValue) external onlyOwner() {
        secretBOverride[tokenId] = newValue;
    }

    function totalSupply() external view returns (uint256) {
        return tokenIdCounter.current();
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "SecretMojo: URI query for nonexistent token");

        if (state == State.REVEALED) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }
        return string(abi.encodePacked(defaultUrl, tokenId.toString()));
    }

    function tokenSecrets(uint256 tokenId) public view virtual returns (uint8 secretA, uint8 secretB) {
        require(_exists(tokenId), "SecretMojo: URI query for nonexistent token");
        require(state == State.PRE_REVEALED || state == State.REVEALED, "SecretMojo: not in Revealed State");

        secretA = secretAOverride[tokenId];
        if (secretA == 0) {
            secretA = uint8((tokenId + secretAShifter) % secretARange) + 1;
        }
        secretB = secretBOverride[tokenId];
        if (secretB == 0) {
            secretB = uint8((tokenId + secretBShifter) % secretBRange) + 1;
        }
    }


    function withdrawEth(uint256 amount, address payable receiver) external onlyOwner() {
        receiver.transfer(amount);
    }
}
