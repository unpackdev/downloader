// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721AUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ExternalEarlyBird.sol";
import "./IGenesisPen.sol";



contract SocratesGenesisPen is Initializable, UUPSUpgradeable, ERC721AUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable, ExternalEarlyBird, IGenesisPen {

    struct Portion {
        uint128 cur;
        uint128 max;
    }

    uint256 public constant MAX_TOKEN = 100_000;
    uint256 public constant TEAM_INIT_TOKEN = 23500 + 7000;
    uint256 public constant DELAY = 3 days;

    Portion[] public portions;

    
    mapping (address => uint256) public consumers;

    string private _baseTokenURI;
    uint256 private _lastTransferTimestamp;

    uint256 public tokenDelay;
    mapping (uint256 => uint256) public lastTokenTransferTimestamp;
    function initialize() initializerERC721A initializer public {
        __ERC721A_init("Socrates Genesis Pen", "SocratesGenesisPen");
        __Ownable_init();
        __Pausable_init();
        _lastTransferTimestamp = 0;
        _baseTokenURI = 'https://images1.socrates.xyz/metadata/eth/';

        portions.push(Portion(0, 46500 + 7000));
        tokenDelay = 1 days;
    }

    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address) internal onlyOwner() override {}

    function authorizedMint(address addr_, uint256 amount_) external nonReentrant whenNotPaused onlyAuthorizedContracts {
        uint256 idx = consumers[msg.sender];
        Portion memory slot = portions[idx];
        require(amount_ > 0, "Socrates: Amount must be greater than 0");
        require(slot.cur + amount_ <= slot.max, "Socrates: Exceeds the max amount of tokens");

        _mint(addr_, amount_);
        portions[idx].cur += uint128(amount_);
    }

     function teamMint(uint128 amount_, address target_) external nonReentrant whenNotPaused onlyOwner onlyEarlyBird {
        require(amount_ > 0, "Socrates: Amount must be greater than 0");
        require(portions[0].cur + amount_ <= unlockAmount(), "Socrates: Exceeds the max amount of team tokens");

        _mint(target_, amount_);

        portions[0].cur += amount_;
    }

    /***********************************|
    |                View               |
    |__________________________________*/

    function unlockAmount() public view returns (uint256) {
        uint256 minterUnlocked = 0;
        uint256 len = portions.length;
        for (uint256 i = 1; i < len; i++) {
            minterUnlocked += portions[i].cur;
        }
        uint256 minted = TEAM_INIT_TOKEN + minterUnlocked / 2;
        return minted > portions[0].max ? portions[0].max : minted;
    }

    function getRemainingBalance(address addr_) external view returns (uint256) {
        Portion memory portion = portions[consumers[addr_]];
        return consumers[addr_] == 0 ? 0 : portion.max - portion.cur;
    }

    function teamSupply() external view returns (uint256) {
        return uint256(portions[0].cur);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        for (uint i = 0; i < quantity; i++) {
            require(block.timestamp > tokenDelay + lastTokenTransferTimestamp[startTokenId + i], "Socrates: transfer is too frequent");
            lastTokenTransferTimestamp[startTokenId+ i] = block.timestamp;
        }
    }

    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory) {
        return super.tokenURI(tokenId_);
    }

    function getToalQuota() public view returns (uint256 total) {
        uint256 len = portions.length;
        for (uint256 i = 0; i < len; i++) {
            total += portions[i].max;
        }
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }


    /***********************************|
    |               Admin               |
    |__________________________________*/
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setTokenDelay(uint256 max_) external onlyOwner {
        tokenDelay = max_;
    }

    function setPortion(address addr_, uint128 max_) external onlyOwner {
        require(consumers[addr_] == 0, "Socrates: Already exists");
        require(getToalQuota() + max_ <= MAX_TOKEN, "Socrates: Exceeds the max amount of total tokens");

        consumers[addr_] = portions.length;
        portions.push(Portion(0, max_));
    }

    function cancelPortion(address addr_) external onlyOwner {
        require(consumers[addr_] != 0, "Socrates: Contract not exists");

        portions[consumers[addr_]].max = portions[0].cur;
    }

    function changePortionMax(address addr_, uint128 max_) external onlyOwner {
        require(consumers[addr_] != 0, "Socrates: Contract not exists");
        require(max_ >= portions[consumers[addr_]].cur, "Socrates: Max must be greater than current");
        require(getToalQuota() + max_ - portions[consumers[addr_]].max <= MAX_TOKEN, "Socrates: Exceeds the max amount of total tokens");

        portions[consumers[addr_]].max = max_;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(block.timestamp > DELAY + _lastTransferTimestamp, "Socrates: Ownership transfer is too frequent");
        _lastTransferTimestamp = block.timestamp;
        super.transferOwnership(newOwner);
    }


    /***********************************|
    |             Modifier              |
    |__________________________________*/

    modifier onlyAuthorizedContracts() {
        require(consumers[msg.sender] != 0, "Socrates: Only authorized contracts can mint");
        _;
    }
}
