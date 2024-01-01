// SPDX-License-Identifier: UNLICENSED

//..........................................................................................
//..........................................................................................
//..........................................................................................
//..............................▒▓.▒....................▒▓.▒....................▒▓..........
//..........▒███████████████████▓▒..▒███████████████████▓...▒███████████████████▓▒..........
//...........▓█████████████████▓.....▓█████████████████▓.....▓█████████████████▓............
//...........▓████▓▓▓▓▓▓▓▓▓▓███▓.....▓████▓▓▓▓▓▓▓▓▓▓███▓.....▓███▓▓▓▓▓▓▓▓▓▓▓███▓............
//...........▓██▓........▒▓████▒.....▓██▒........▒▓████▒.....▓██▒........▒▓████▒............
//...........▓█▓........▒█████▓......▓█▓........▒█████▓......▓█▓........▒█████▓.............
//...........▓█▒........▓█████▒......▓▓▒........▓█████▒......██▒........▓█████▒.............
//...........█▓........▒█████▓.......█▒........▒█████▓.......█▒........▒█████▓..............
//..........▒▓.........▓█████▒......▒▒.........▓█████▒......▒▒.........▓█████▒..............
//..........▒.........▒█████▓.......▒.........▒█████▓.................▒█████▓...............
//....................▓█████▒.................▓█████▒.................▓█████▒...............
//...................▒█████▓.................▒█████▓.................▒█████▓................
//...................▓█████▒.................▓█████▒.................▓█████▒................
//..................▒█████▓.................▒█████▓.................▒█████▓.................
//..................▓█████▒.................▓█████▒.................▓█████▒.................
//.................▒█████▓.................▒█████▓.................▒█████▓..................
//.................▓█████▓.................▓█████▓................▒▓█████▓..................
//................▓███▓▓▒▒▒...............▓███▓▒▒▒▒...............▓███▓▒▒▒▒.................
//...............▒██▓▒...................▒██▓▒...................▒██▓▒......................
//..............▒▓▓▒....................▒█▓▒....................▒█▓▒........................
//.............▒▓▓▒....................▒▓▓.....................▒▓▒..........................
//...........▒▒▒▒...................▒▒▒▒....................▒▒▒▒............................
//..........................................................................................
//..........................................................................................
//..........................................................................................
//...............................................................█ LUX^TENEBRARUM █.........
//..........................................................................................
//..........................................................................................


// built with ♥ by @0xArchitect
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./WhiteListSigner.sol";
import "./ICreepCrewAditus.sol";

contract CreepCrewAditusMintingLogic is
Initializable,
PausableUpgradeable,
Ownable2StepUpgradeable,
Whitelist{
    
    ICreepCrewAditus public creepCrewAditus;
    
    uint256 public MAX_MINT_PER_WALLET;
    uint256 public MAX_MINT_PER_TX;
    uint256 public MINT_PRICE;
    uint256 public MAX_SUPPLY;
    uint256 public TEAM_ALLOCATION;
    uint256 public MYSTERY_BOX_ALLOCATION;
    address public designatedSigner;
    uint256 public PUBLIC_ALLOCATION;
    uint256 public WHITELIST_MINT_START_TIME;
    uint256 public PUBLIC_LIST_START_TIME;
    
    mapping(address => uint256) public mintCount;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address _creepcrewAditus, uint256 whitelistStartTime) external initializer {
        __Ownable2Step_init();
        __Pausable_init();
        __WhiteList_init();
        MAX_MINT_PER_WALLET = 1;
        MAX_MINT_PER_TX = 1;
        MINT_PRICE = 0;
        TEAM_ALLOCATION = 77;
        MYSTERY_BOX_ALLOCATION = 17;
        MAX_SUPPLY = 777;
        WHITELIST_MINT_START_TIME = whitelistStartTime;
        PUBLIC_LIST_START_TIME = WHITELIST_MINT_START_TIME + 7 hours;
        PUBLIC_ALLOCATION = MAX_SUPPLY - TEAM_ALLOCATION - MYSTERY_BOX_ALLOCATION;
        creepCrewAditus = ICreepCrewAditus(_creepcrewAditus);
    }
    
    modifier onlyWhitelisted(whitelist memory _whitelist) {
        require(getSigner(_whitelist) == designatedSigner, "Invalid signature");
        require(_whitelist.userAddress == msg.sender, "Invalid list type");
        _;
    }
    
    // Minting Functions --(public/team)--
    
    function whitelistMint(whitelist memory signature, uint256 amount) external payable onlyWhitelisted(signature) {
        require(creepCrewAditus.totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        require(amount <= MAX_MINT_PER_TX, "Max mint per tx exceeded");
        require(mintCount[msg.sender] + amount <= MAX_MINT_PER_WALLET, "Max mint per wallet exceeded");
        require(amount <= PUBLIC_ALLOCATION, "Public allocation exceeded");
        require(msg.value == MINT_PRICE * amount, "Invalid amount");
        require(block.timestamp >= WHITELIST_MINT_START_TIME, "Minting not started");
        
        PUBLIC_ALLOCATION -= amount;
        mintCount[msg.sender] += amount;
        creepCrewAditus.mint(amount, msg.sender);
    }
    
    function publicMint(uint256 amount) external payable {
        require(creepCrewAditus.totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        require(amount <= MAX_MINT_PER_TX, "Max mint per tx exceeded");
        require(mintCount[msg.sender] + amount <= MAX_MINT_PER_WALLET, "Max mint per wallet exceeded");
        require(amount <= PUBLIC_ALLOCATION, "Public allocation exceeded");
        require(msg.value == MINT_PRICE * amount, "Invalid amount");
        require(block.timestamp >= PUBLIC_LIST_START_TIME, "Minting not started");
        
        PUBLIC_ALLOCATION -= amount;
        mintCount[msg.sender] += amount;
        creepCrewAditus.mint(amount, msg.sender);
    }
    
    function mintToTeam(address to, uint256 amount) external onlyOwner {
        require(creepCrewAditus.totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        require(amount <= TEAM_ALLOCATION, "Team allocation exceeded");
        TEAM_ALLOCATION -= amount;
        creepCrewAditus.mint(amount, to);
    }
    
    function mintToMysteryBox(address to, uint256 amount) external onlyOwner {
        require(creepCrewAditus.totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        require(amount <= MYSTERY_BOX_ALLOCATION, "Mystry box allocation exceeded");
        MYSTERY_BOX_ALLOCATION -= amount;
        creepCrewAditus.mint(amount, to);
    }
    
    
    // Contract Setup Functions --(onlyOwner)--
    
    function setWhitelistMintStartTime(uint256 _whitelistMintStartTime) public onlyOwner {
        WHITELIST_MINT_START_TIME = _whitelistMintStartTime;
    }
    
    function setPublicMintStartTime(uint256 _publicMintStartTime) public onlyOwner {
        PUBLIC_LIST_START_TIME = _publicMintStartTime;
    }
    
    function setPublicAllocation(uint256 _publicAllocation) public onlyOwner {
        PUBLIC_ALLOCATION = _publicAllocation;
    }
    
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }
    
    function setMaxMintPerWallet(uint256 _maxMintPerWallet) public onlyOwner {
        MAX_MINT_PER_WALLET = _maxMintPerWallet;
    }
    
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        MINT_PRICE = _mintPrice;
    }
    
    function setMaxMintPerTx(uint256 _maxMintPerTx) public onlyOwner {
        MAX_MINT_PER_TX = _maxMintPerTx;
    }
    
    function setTeamAllocation(uint256 _teamAllocation) public onlyOwner {
        TEAM_ALLOCATION = _teamAllocation;
    }
    
    function setMysteryBoxAllocation(uint256 _mysteryBoxAllocation) public onlyOwner {
        MYSTERY_BOX_ALLOCATION = _mysteryBoxAllocation;
    }
    
    function setDesignatedSigner(address _designatedSigner) public onlyOwner {
        designatedSigner = _designatedSigner;
    }
    
    function setCrewContract(address _creepCrewAditus) public onlyOwner {
        creepCrewAditus = ICreepCrewAditus(_creepCrewAditus);
    }
    
    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
    }
    
    // Getter
    
    function totalSupply() external view returns(uint256) {
        return creepCrewAditus.totalSupply();
    }
}

