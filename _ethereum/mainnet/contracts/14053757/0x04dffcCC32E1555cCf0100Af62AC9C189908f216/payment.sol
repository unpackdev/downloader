// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.7;


import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";


interface HeadStaking {
    function depositsOf(address account) external view returns (uint256[] memory);
}

interface IHead {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IStaking {
  function stakeMany(address account, uint16[] calldata tokenIds) external;
  function randomHunterOwner(uint256 seed) external view returns (address);
}

interface IMint {
  struct Traits {uint8 alphaIndex; bool isHunter;}
  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (Traits memory);
  function minted() external view returns (uint16);
  function mint(address recipient) external;

}

contract paymentContract is ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable  {
  
  IStaking public stakingContract;                                          
  IHead public ERC20Token;               
  IMint public ERC721Contract;      
  HeadStaking public HeadDAOStaking;   

  
  using AddressUpgradeable for address;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; 
  using CountersUpgradeable for CountersUpgradeable.Counter;



  struct PendingCommits {bool stake; uint16 amount;}

  uint256 public HeadDaoMinted;
  uint256 public HeadDAOExpiry;
  uint256 private pendingMintAmt;

  bool public hasPublicSaleStarted;

  mapping (address => uint256) public daoMints;
  mapping (address => bool)     private whitelistedContracts;    
  mapping(uint256 => uint256) private _tokenIndex; 
  mapping(address => uint256) private _pendingCommitId;  
  mapping(address => mapping(uint256 => PendingCommits)) private _pendingCommits;        
  mapping (uint16 => bool) public daoUsedTokens;  
  mapping(address => bool)      public  whitelists;           

  uint256 public MAX_TOKENS;    
  uint256 private PAID_TOKENS;         
  uint256 public MINT_PRICE;    

  uint256[] internal seeds;  
  uint256 seed_interval;
  uint256 _nextID;

  function initialize(uint256 _maxTokens) initializer public {

    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    _pause();

    MINT_PRICE = 0.07 ether;   
    MAX_TOKENS = _maxTokens;
    PAID_TOKENS = _maxTokens / 5;
    _nextID = 0;
    seed_interval = 100;
    HeadDAOExpiry = block.timestamp + 172800;

    _addSeed();


  }


  function commitMint(uint256 amount, bool stake) external payable whenNotPaused {
    address msgSender = _msgSender();
    uint256 minted = ERC721Contract.minted() + pendingMintAmt;

    require(hasPublicSaleStarted,"Public Sale is not live");
    require(tx.origin == msgSender, "Only EOA");
    require(minted + amount <= MAX_TOKENS, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");

    require(_pendingCommitId[msgSender] == 0, "Already have pending mints");

    if (minted < PAID_TOKENS) {
      require(minted + amount <= PAID_TOKENS, "All tokens on-sale already sold");
      require(MINT_PRICE * amount == msg.value, "Invalid payment amount");
    } else {
      require(msg.value == 0);

    }
    uint256 headCost = 0;   

    for (uint i = 0; i < amount; i++) {
      minted++;
      if (minted % seed_interval == 0){
        _addSeed();
      }

      headCost += mintCost(minted);
    }

    if (headCost > 0) {
      ERC20Token.burn(msgSender, headCost);
    }

    uint16 amt = uint16(amount);
    _pendingCommits[msgSender][_nextID] = PendingCommits(stake, amt);
    _pendingCommitId[msgSender] = _nextID;
    pendingMintAmt += amount;

  }
  
  mapping(uint256 => address) private headDaoOwners; 

  function commitMint_whitelist(bool stake) external  whenNotPaused {
    address msgSender = _msgSender();
    uint256 minted = ERC721Contract.minted() + pendingMintAmt;
    uint256 amount = 1;

    require(block.timestamp < HeadDAOExpiry, "the free mint timeframe is over");
    require(minted >= PAID_TOKENS, "Head DAO Minting phase not started");
    require(minted + amount <= MAX_TOKENS, "All tokens minted");
    require(HeadDaoMinted + amount <= 10000, "No more Head DAO free mints Left");
    require(amount > 0 && amount <= 10, "Invalid Amount to mint");
    require(tx.origin == msgSender, "Only EOA");
    require(whitelists[msgSender], "You are not whitelisted");
    require(_pendingCommitId[msgSender] == 0, "Already have pending mints");

    HeadDaoMinted += amount;
    whitelists[msgSender] = false;

    for (uint i = 0; i < amount; i++) {      
      minted++;
      if (minted % seed_interval == 0){
        _addSeed();
      }
    }

    uint16 amt = uint16(amount);
    _pendingCommits[msgSender][_nextID] = PendingCommits(stake, amt);
    _pendingCommitId[msgSender] = _nextID;
    pendingMintAmt += amount;

  }


  mapping(address => mapping (uint => bool)) private stakedTokenIDs;

  function commitMint_headDAO(uint16[] calldata daotokenIds, bool stake) external whenNotPaused {
    address msgSender = _msgSender();
    uint256 minted = ERC721Contract.minted() + pendingMintAmt;
    uint256[] memory deposits = HeadDAOStaking.depositsOf(msgSender);
    uint256 amount = daotokenIds.length;

    require(deposits.length > 0, "You are not a staker");
    require(block.timestamp < HeadDAOExpiry, "the free mint timeframe is over");
    require(minted >= PAID_TOKENS, "Head DAO Minting phase not started");
    require(minted + amount <= MAX_TOKENS, "All tokens minted");
    require(HeadDaoMinted + amount <= 10000, "No more Head DAO free mints Left");
    require(amount > 0 && amount <= 10, "Invalid Amount to mint");
    require(tx.origin == msgSender, "Only EOA");

    require(_pendingCommitId[msgSender] == 0, "Already have pending mints");

    daoMints[msgSender] += amount;
    HeadDaoMinted += amount;

    for (uint i = 0; i < deposits.length; i++) {
      stakedTokenIDs[msgSender][deposits[i]] = true;
    }

    for (uint i = 0; i < amount; i++) {
      uint16 daoTokenID = daotokenIds[i];
      require(!daoUsedTokens[daoTokenID],"Token Already Used to Mint");
      require(stakedTokenIDs[msgSender][daoTokenID], "You don't own this Token ID");

      daoUsedTokens[daoTokenID] = true;
      minted++;
      if (minted % seed_interval == 0){
        _addSeed();
      }
    }

    uint16 amt = uint16(amount);
    _pendingCommits[msgSender][_nextID] = PendingCommits(stake, amt);
    _pendingCommitId[msgSender] = _nextID;
    pendingMintAmt += amount;

  }

  

  function reveal(address addr) internal {

    uint256 _seedID = _pendingCommitId[addr];
    require(_seedID > 0, "No pending commit");
    require(seeds[_seedID] != 0, "seed is Not ready");

    PendingCommits memory commit = _pendingCommits[addr][_seedID];

    uint16 amount = commit.amount;
    uint16[] memory tokenIds = new uint16[](amount);
    uint16 minted = ERC721Contract.minted();
    uint256 seed = seeds[_seedID];

    pendingMintAmt -= amount;
    _pendingCommitId[addr] = 0;

    for (uint i = 0; i < amount; i++) {
      
      minted++;      
      uint256 receip_seed = uint256(keccak256(abi.encodePacked(seed,minted)));                                                                                                        
      address recipient = selectRecipient(receip_seed,minted);    
      
      if (!commit.stake) {                                           
        ERC721Contract.mint(recipient);

      } else {
        ERC721Contract.mint(address(stakingContract));
        tokenIds[i] = minted;
      }

 
      _tokenIndex[minted] = _seedID;

    }

    if (commit.stake) stakingContract.stakeMany(addr, tokenIds);

    delete _pendingCommits[addr][_seedID];
    

  }

  function mintReveal() external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender() && !_msgSender().isContract(), "Only EOA1");

    reveal(_msgSender());
  }

  function setPublicSaleStart(bool started) external onlyOwner {
    hasPublicSaleStarted = started;
  }

  function selectRecipient(uint256 seed, uint256 minted) private view returns (address) {

    
    if (minted <= PAID_TOKENS || ((seed >> 245) % 10) != 0) return _msgSender();  

    address thief = stakingContract.randomHunterOwner(seed >> 144);                                         
    if (thief == address(0x0)) return _msgSender();
    return thief;

  }

  function mintCost(uint256 tokenId) public view returns (uint256) {
    if (tokenId <= PAID_TOKENS) return 0;                           
    if (tokenId <= 30000 ) return 200 ether;          
    if (tokenId <= 40000) return 400 ether;         
    return 800 ether;                                            
  }

  function setWhitelistContract(address contract_address, bool status) public onlyOwner{
      whitelistedContracts[contract_address] = status;
  }

  function setStaking(address _staking) external onlyOwner {
    stakingContract = IStaking(_staking);
  }

  function setERC20token(address _erc20Address) external onlyOwner {
      ERC20Token = IHead(_erc20Address);  
  }

  function setERC721Contract(address _mintContract) external onlyOwner {
    ERC721Contract = IMint(_mintContract);
  }
  
  function setInit(address _mintContract, address _staking, address _erc20Address, address _headdaostaking) public onlyOwner {
    stakingContract = IStaking(_staking);
    ERC20Token = IHead(_erc20Address);  
    ERC721Contract = IMint(_mintContract);
    HeadDAOStaking = HeadStaking(_headdaostaking);  
    
  }

  function setPaidTokens(uint256 _paidTokens) external onlyOwner {
    PAID_TOKENS = _paidTokens;
  }

  function setPaused(bool _paused) external onlyOwner {
    require(address(ERC20Token) != address(0) && address(stakingContract) != address(0), "Contracts are not set");
    if (_paused) _pause();
    else _unpause();
  }

  function withdraw() public payable onlyOwner {
    
    uint256 ddungeon = (address(this).balance * 35) / 100;  
    uint256 modPay = (address(this).balance * 5) / 100;  
    uint256 daoPortion = (address(this).balance * 15) / 100;        
    uint256 dev = (address(this).balance * 85) / 1000;  
    uint256 verd = (address(this).balance * 4) / 100;  
    uint256 security = (address(this).balance * 5) / 100;  
    uint256 extra = (address(this).balance * 5) / 100;  
    uint256 sham = (address(this).balance * 225) / 1000;  

		payable(0x11360F0c5552443b33720a44408aba01a809905e).transfer(sham);
    payable(0x177F994565d8bbA819D45b5a32C962ED091B9dA5).transfer(modPay);
    payable(0xf2018871debce291588B4034DBf6b08dfB0EE0DC).transfer(daoPortion);
    payable(0x9C8227FE7FE01F8278da8F7b9963Ed38c0603577).transfer(extra);
    payable(0x09814aaf2a03d944833180C2a4Dcaa2612fa672d).transfer(ddungeon);
    payable(0xE2e35768cC25d0120D719f64eaC64cf6efFfff45).transfer(security);
    payable(0x2D3840C060dfb7f311E08fe3c1e21Feca6C74B56).transfer(dev);
    payable(0xA684399B5230940a84a17be6340369D7A18A664F).transfer(verd);

  }

  function setDAOexpiry(uint256 _new) external onlyOwner {
    HeadDAOExpiry = _new;
  }

  function testMint() external onlyOwner {
    MINT_PRICE = 0;
  }

  // SEED 
  function get_seed(uint256 tokenId) external view returns (uint256) {
    uint256 seedIndex = _tokenIndex[tokenId];
    require(seeds[seedIndex] != 0, "seed is Not ready");
    return seeds[seedIndex];

  }

  function last_seed() external view returns (uint256) {
    return seeds[seeds.length-1];

  }

  function changeSeedInterval(uint256 _new) external onlyOwner{
    seed_interval = _new;
  }

  function _addSeed() private {
    seeds.push(uint256(blockhash(block.number - 1)));
    _nextID ++;   
  }

  function force_seed() external onlyOwner {
    _addSeed();
  }

  function addRandomSeed(uint256 seed) external {
    require(owner() == _msgSender() || whitelistedContracts[_msgSender()], "Only admins can call this");
    seeds.push(seed);
    _nextID ++;   
  }

  // Commit Stuff
  function getPendingMint(address addr) external view returns (PendingCommits memory) {
    require(_pendingCommitId[addr] != 0, "no pending commits");
    return _pendingCommits[addr][_pendingCommitId[addr]];
  }

  function hasMintPending(address addr) external view returns (bool) {
    return _pendingCommitId[addr] != 0;
  }
  
  function canMint(address addr) external view returns (bool) {
    return _pendingCommitId[addr] != 0 && seeds[_pendingCommitId[addr]] > 0;
  }

  function forceRevealCommit(address addr) external {
    require(owner() == _msgSender() || whitelistedContracts[_msgSender()], "Only admins can call this");
    reveal(addr);
  }

  function add_whitelist(address[] calldata addresses) external onlyOwner {
    uint256 length = addresses.length;
    for (uint256 i; i < length; i++ ){
          whitelists[addresses[i]] = true;
    }
  }

  function getPaidTokens() external view returns (uint256) {
    return PAID_TOKENS;
  }

  function getInterval() external view returns (uint256) {
    return seed_interval;
  }

  function getTotalMinted() external view returns (uint256){
    uint256 minted = ERC721Contract.minted() + pendingMintAmt;
    return minted;
  }


  function withdrawNew() public payable onlyOwner {
    
    uint256 ddungeon = (address(this).balance * 35) / 100;  
    uint256 modPay = (address(this).balance * 5) / 100;  
    uint256 daoPortion = (address(this).balance * 15) / 100;        
    uint256 dev = (address(this).balance * 85) / 1000;  
    uint256 verd = (address(this).balance * 4) / 100;  
    uint256 security = (address(this).balance * 5) / 100;  
    uint256 extra = (address(this).balance * 5) / 100;  
    uint256 sham = (address(this).balance * 225) / 1000;  

		payable(0x11360F0c5552443b33720a44408aba01a809905e).transfer(sham);
    payable(0x177F994565d8bbA819D45b5a32C962ED091B9dA5).transfer(modPay);
    payable(0xC7216f7AAE4C253962d30693EB15023e80C04633).transfer(daoPortion);
    payable(0x9C8227FE7FE01F8278da8F7b9963Ed38c0603577).transfer(extra);
    payable(0x09814aaf2a03d944833180C2a4Dcaa2612fa672d).transfer(ddungeon);
    payable(0xE2e35768cC25d0120D719f64eaC64cf6efFfff45).transfer(security);
    payable(0x2D3840C060dfb7f311E08fe3c1e21Feca6C74B56).transfer(dev);
    payable(0xA684399B5230940a84a17be6340369D7A18A664F).transfer(verd);

  }



}