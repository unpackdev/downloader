// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;


import "./Initializable.sol";

// Utility Libraries
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";


// Security Libraries 
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";


// Token Libraries
import "./IERC20Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./VRFConsumerBaseUpgradeable.sol";



interface ISlime {
  function bigSlime(uint256 xyz) external returns (uint256 slime);
}

interface IDen {
  struct BigDragon {uint8 alphaIndex; bool isKnight; bool isDonkey; bool isZombie; }
  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (BigDragon memory);
  function ownerOf(uint256 tokenId) external view returns (address);
  function safeTransferFrom(address from,address to,uint256 tokenId) external; 
  function transferFrom(address from, address to, uint256 tokenId) external;
  function safeTransferFrom(address from,address to,uint256 tokenId,  bytes memory _data) external; 
  function transferFrom(address from, address to, uint256 tokenId,  bytes memory _data) external;
}

interface IGold {
  function mint(address to, uint256 amount) external;
  function updateOriginAccess() external;
}

contract DarkCave is OwnableUpgradeable, IERC721ReceiverUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; 

                             
  struct Stake {uint16 tokenId; uint80 value; address owner;}


  IDen public den;                                                                
  IGold public gold;               
  ISlime public slime;         


  bool public rescueEnabled;                                          


  event TokenStaked   (address owner,   uint256 tokenId, uint256 value);
  event KnightClaimed (uint256 tokenId, uint256 earned,  bool unstaked);
  event DragonClaimed (uint256 tokenId, uint256 earned,  bool unstaked);

  mapping (address => bool)    private whitelistedContracts;  
  mapping (uint256 => Stake)   private battleGround;                              
  mapping (uint256 => Stake[]) private Dragons;                                
  mapping (address => EnumerableSetUpgradeable.UintSet) private _deposits;
  mapping (uint256 => uint256) private packIndices;                         
  
  uint256 private _totalAlphaStaked;                              
  uint256 private _unaccountedRewards;                               
  uint256 private _GoldPerAlpha;     
  uint256 private _totalGoldEarned;                                    
  uint256 private _totalKnightsStaked;                           
  uint256 private _lastClaimTimestamp;    
   

  uint256 public  DAILY_GOLD_RATE;                      
  uint256 public  MINIMUM_TO_EXIT;                        
  uint256 public  GOLD_TAX;            
  uint256 public  MAX_GOLD;      
  uint8   public  MAX_ALPHA; 

                          

                      
  function initialize(address _den, address _gold, address _slime) initializer public {

    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();


    den = IDen(_den);                                                  
    gold = IGold(_gold);    
    slime = ISlime(_slime);                                          

    _totalAlphaStaked = 0;                                    
    _unaccountedRewards = 0;                                  
    _GoldPerAlpha = 0;   
    MAX_GOLD = 2400000000 ether; 
    MAX_ALPHA = 9; 

    DAILY_GOLD_RATE = 12000 ether;                        
    MINIMUM_TO_EXIT = 2 days;                              
    GOLD_TAX = 20; 
  
    rescueEnabled = false; 


  }


    /** MAIN GAME PLAY */

  function addManyToCave(address account, uint16[] calldata tokenIds) external blockExternalContracts whenNotPaused nonReentrant() {   
    require(account == _msgSender() || _msgSender() == address(den), "DONT GIVE YOUR TOKENS AWAY");   


    for (uint i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(den)) {

        require(den.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
        den.transferFrom(_msgSender(), address(this), tokenIds[i]);  //safeTransferFrom
        
      } else if (tokenIds[i] == 0) {
        continue; 
      }

      if (isKnight(tokenIds[i])) 
        _addKnightsToCave(account, tokenIds[i]);

      else 
        _sendDragonsHunting(account, tokenIds[i]);
    }
  }

  function claimManyFromCave(uint16[] calldata tokenIds, bool unstake) external blockExternalContracts whenNotPaused _updateEarnings nonReentrant() {

    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    require(tx.origin == _msgSender(), "Only EOA");


    uint256  owed = 0;
    
    for (uint i = 0; i < tokenIds.length; i++) {
      if (isKnight(tokenIds[i]))
        owed += _claimKnights(tokenIds[i], unstake);
      else
        owed += _claimDragons(tokenIds[i], unstake);
    }

    gold.updateOriginAccess();

    if (owed == 0) return;
    gold.mint(_msgSender(), owed);


  }
  
  function calcKnightsGold(uint256 tokenId) public view blockExternalContracts returns (uint256 owed) {

    Stake memory stake = battleGround[tokenId];
    if (_totalGoldEarned < MAX_GOLD) {
        owed = (block.timestamp - stake.value) * DAILY_GOLD_RATE / 1 days;

    } else if (stake.value > _lastClaimTimestamp) {
        owed = 0;

    } else {
        owed = (_lastClaimTimestamp - stake.value) * DAILY_GOLD_RATE / 1 days; 
    }

  }

  function calcDragonsGold(uint256 tokenId) public view blockExternalContracts returns (uint256 owed) {

    uint256 alpha = _alphaForDragon(tokenId);  
    Stake memory stake = Dragons[alpha][packIndices[tokenId]];
    owed = (alpha) * (_GoldPerAlpha - stake.value); 


  }

  function rescue(uint256[] calldata tokenIds) external blockExternalContracts nonReentrant() {
    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    require(tx.origin == _msgSender(), "Only EOA");
    require(rescueEnabled, "RESCUE DISABLED");
    
    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint256 alpha;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (isKnight(tokenId)) {

        stake = battleGround[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        delete battleGround[tokenId];
        _totalKnightsStaked -= 1;
        _deposits[_msgSender()].remove(tokenId);
        den.safeTransferFrom(address(this), _msgSender(), tokenId, ""); 
        emit KnightClaimed(tokenId, 0, true);


      } else {
        alpha = _alphaForDragon(tokenId);
        stake = Dragons[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        _totalAlphaStaked -= alpha; 
        lastStake = Dragons[alpha][Dragons[alpha].length - 1];
        Dragons[alpha][packIndices[tokenId]] = lastStake; 
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        Dragons[alpha].pop(); 
        delete packIndices[tokenId]; 
        _deposits[_msgSender()].remove(tokenId);
        den.safeTransferFrom(address(this), _msgSender(), tokenId, ""); 
        emit DragonClaimed(tokenId, 0, true);
      }
    }
  }

  /** PRIVATE GAMEPLAY FUNCTIONS */

  function _addKnightsToCave(address account, uint256 tokenId) private  _updateEarnings {
    battleGround[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    _totalKnightsStaked += 1;
   
    emit TokenStaked(account, tokenId, block.timestamp);
    _deposits[account].add(tokenId);
  }

  function _sendDragonsHunting(address account, uint256 tokenId) private _updateEarnings  {
    uint256 alpha = _alphaForDragon(tokenId);
    _totalAlphaStaked += alpha;                                               
    packIndices[tokenId] = Dragons[alpha].length;                                
    Dragons[alpha].push(Stake({                                                
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(_GoldPerAlpha)
    })); 
    emit TokenStaked(account, tokenId, _GoldPerAlpha);
    _deposits[account].add(tokenId);
  }

  function _claimKnights(uint256 tokenId, bool unstake) private returns (uint256 owed) {

    Stake memory stake = battleGround[tokenId];

    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(tx.origin == _msgSender(), "Only EOA");
    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "KNIGHTS CANT GO HOME TO THEIR WIVES WITHOUT 2 DAYS GOLD");

    owed = calcKnightsGold(tokenId);

    if (unstake) {
         
      if (slime.bigSlime(tokenId) & 1 == 1) {                                         
        _payDragonsTax(owed);
        owed = 0;  
      }

      delete battleGround[tokenId];
      _totalKnightsStaked -= 1;
      _deposits[_msgSender()].remove(tokenId);
      den.safeTransferFrom(address(this), _msgSender(), tokenId, "");       

    } else {

      _payDragonsTax(owed * GOLD_TAX / 100);                 
      battleGround[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      });
      owed = owed * (100 - GOLD_TAX) / 100;                 
    }
    emit KnightClaimed(tokenId, owed, unstake);
  }

  function _claimDragons(uint256 tokenId, bool unstake) private returns (uint256 owed) {

    uint256 alpha = _alphaForDragon(tokenId);  
    Stake memory stake = Dragons[alpha][packIndices[tokenId]];

    require(den.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");                
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(tx.origin == _msgSender(), "Only EOA");
    require(!_msgSender().isContract(), "Contracts are not allowed big man");

    owed = calcDragonsGold(tokenId);                                        

    if (unstake) {
      _totalAlphaStaked -= alpha;                                          
      Stake memory lastStake = Dragons[alpha][Dragons[alpha].length - 1];       
      Dragons[alpha][packIndices[tokenId]] = lastStake;                       
      packIndices[lastStake.tokenId] = packIndices[tokenId];               
      Dragons[alpha].pop();                                                  

      delete packIndices[tokenId];                                       
      _deposits[_msgSender()].remove(tokenId);
      den.safeTransferFrom(address(this), _msgSender(), tokenId, "");    


    } else {

      Dragons[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(_GoldPerAlpha)
      }); // reset stake

    }
    emit DragonClaimed(tokenId, owed, unstake);
  }

  function _payDragonsTax(uint256 amount) private {

    if (_totalAlphaStaked == 0) {                                             
      _unaccountedRewards += amount; 
      return;
    }

    _GoldPerAlpha += (amount + _unaccountedRewards) / _totalAlphaStaked;        
    _unaccountedRewards = 0;
  }
                                   
  function _alphaForDragon(uint256 tokenId) private view returns (uint8) {

    IDen.BigDragon memory yo = den.getTokenTraits(tokenId);
    return MAX_ALPHA - yo.alphaIndex; 
  }


  /** ADMIN FUNCTIONS */

  function setWhitelistContract(address contract_address, bool status) external onlyOwner{
    whitelistedContracts[contract_address] = status;
  }

  function setSlime(address _slime) external onlyOwner {

      slime = ISlime(_slime);

  }

  function setDen(address _den) external onlyOwner {
      den = IDen(_den);   
  }

  function setGold(address _gold) external onlyOwner {
      gold = IGold(_gold);  
  }

  function setInit(address _den, address _gold, address _slime) external onlyOwner{
    den = IDen(_den);                                          
    gold = IGold(_gold);  
    slime = ISlime(_slime);                                      

  }

  function changeDailyRate(uint256 _newRate) external onlyOwner{
      DAILY_GOLD_RATE = _newRate;
  }

  function changeMinExit(uint256 _newExit) external onlyOwner{
      MINIMUM_TO_EXIT = _newExit ;
  }

  function changeGoldTax(uint256 _newTax) external onlyOwner {
      GOLD_TAX = _newTax;
  }

  function changeMaxGold(uint256 _newMax) external onlyOwner {
      MAX_GOLD = _newMax;
  }

  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /** OTHER */
  
  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {

    require(from == address(0x0), "Cannot send tokens to Cave directly");
    return IERC721ReceiverUpgradeable.onERC721Received.selector;

  }

  /** GAME PLAY EXTERNAL FUNCTIONS */

  function GoldPerAlpha() external view blockExternalContracts returns (uint256 goldAlpha) {
    goldAlpha = _GoldPerAlpha;
  }                           

  function unaccountedRewards() external view blockExternalContracts returns (uint256 rewards) {

    rewards = _unaccountedRewards;
  }    

  function lastClaimTimestamp() external view blockExternalContracts returns (uint256 timestamp) {
    timestamp = _lastClaimTimestamp;
  }    

  function totalKnightsStaked() external view blockExternalContracts returns (uint256 totalKnights) {
    totalKnights = _totalKnightsStaked;
  }    

  function totalGoldEarned() external view blockExternalContracts returns (uint256 totalGold) {
    totalGold = _totalGoldEarned;
  }    

  function depositsOf(address account) external view blockExternalContracts  returns (uint256[] memory) {

    EnumerableSetUpgradeable.UintSet storage depositSet = _deposits[account];
    uint256[] memory tokenIds = new uint256[] (depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
      tokenIds[i] = depositSet.at(i);
    }

    return tokenIds;
  }

  function randomDragonOwner(uint256 seed) external view blockExternalContracts returns (address) {

    if (_totalAlphaStaked == 0) return address(0x0);

    uint256 bucket = (seed & 0xFFFFFFFF) % _totalAlphaStaked;                 
    uint256 cumulative;
    seed >>= 32;

    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {                    
      cumulative += Dragons[i].length * i;
      if (bucket >= cumulative) continue;                                 

      return Dragons[i][seed % Dragons[i].length].owner;                       
    }

    return address(0x0);
  }

  function isKnight(uint256 tokenId) public view blockExternalContracts returns (bool knight) {
    IDen.BigDragon memory yo = den.getTokenTraits(tokenId);
    return yo.isKnight;
  }

  function calculateReward(uint16[] calldata tokenIds) external view blockExternalContracts returns (uint256 owed) {

    for (uint i = 0; i < tokenIds.length; i++) {
      if (isKnight(tokenIds[i]))
        owed += calcKnightsGold(tokenIds[i]);
      else
        owed +=  calcDragonsGold(tokenIds[i]);
    }
  
  }

  /** SECURITY  */

  modifier blockExternalContracts() {
    if (tx.origin != msg.sender) {
      require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
      _;
      
    } else {

      _;

    }
    
  }

  modifier _updateEarnings() {

    if (_totalGoldEarned < MAX_GOLD) {
      _totalGoldEarned += 
        (block.timestamp - _lastClaimTimestamp)
        * _totalKnightsStaked
        * DAILY_GOLD_RATE / 1 days; 
      _lastClaimTimestamp = block.timestamp;
    }
    _;
  }
  
}