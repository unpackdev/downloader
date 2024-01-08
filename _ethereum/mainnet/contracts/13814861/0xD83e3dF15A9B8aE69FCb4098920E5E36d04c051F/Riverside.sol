// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;


import "./Initializable.sol";

// Utility Libraries
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./MathUpgradeable.sol";




// Security Libraries 
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";


// Token Libraries
import "./IERC20Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./VRFConsumerBaseUpgradeable.sol";


import "./RoarGenX.sol";
import "./RiverGenX.sol";




interface Roar {
  struct ManBear {bool isFisherman; uint8[14] traitarray; uint8 alphaIndex;}
  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (ManBear memory);
  function ownerOf(uint256 tokenId) external view returns (address);
  function safeTransferFrom(address from,address to,uint256 tokenId) external; 
  function transferFrom(address from, address to, uint256 tokenId) external;
  function safeTransferFrom(address from,address to,uint256 tokenId,  bytes memory _data) external; 
  function transferFrom(address from, address to, uint256 tokenId,  bytes memory _data) external;
}


interface GenXInterface {
  struct ManBear {bool isFisherman; uint8[14] traitarray; uint8 alphaIndex;}
  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (ManBear memory);
  function ownerOf(uint256 tokenId) external view returns (address);
  function safeTransferFrom(address from,address to,uint256 tokenId) external; 
  function transferFrom(address from, address to, uint256 tokenId) external;
  function safeTransferFrom(address from,address to,uint256 tokenId,  bytes memory _data) external; 
  function transferFrom(address from, address to, uint256 tokenId,  bytes memory _data) external;
}




contract RiverSide is OwnableUpgradeable, IERC721ReceiverUpgradeable, PausableUpgradeable, VRFConsumerBaseUpgradeable, ReentrancyGuardUpgradeable {
  using AddressUpgradeable for address;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; 

                             
  struct Stake {
    uint16 tokenId;
    uint80 value;
    address owner;
  }


  /** INTERFACES */
  Roar roar;                                                                 // reference to the Roar NFT contract
  ITSalmon salmon;                                                           // reference to the $SALMON contract for minting $SALMON earnings



  event TokenStaked(address owner, uint256 tokenId, uint256 value);
  event FishermanClaimed(uint256 tokenId, uint256 earned, bool unstaked);
  event BearClaimed(uint256 tokenId, uint256 earned, bool unstaked);

  mapping (address => bool) whitelistedContracts;      
  mapping(uint256 => Stake) public riverside;                                 // maps tokenId to stake
  mapping(uint256 => Stake[]) public Bears;                                   // maps alpha to all Bear stakes with that alpha
  mapping(address => EnumerableSetUpgradeable.UintSet) private _deposits;
  mapping(uint256 => uint256) public packIndices;                             // tracks location of each Bear in Pack
  
  
  uint256 public totalAlphaStaked;                                  // total alpha scores staked
  uint256 public unaccountedRewards;                                  // any rewards distributed when no bears are staked
  uint256 public SalmonPerAlpha;                                      // amount of $SALMON due for each alpha point staked


  uint256 public  DAILY_SALMON_RATE ;                       // Fisherman earn 10000 $SALMON per day
  uint256 public  MINIMUM_TO_EXIT;                         // Fisherman must have 2 days worth of $SALMON to unstake or else it's too cold
  
  /** Constant Parameters*/
  uint256 public  SALMON_CLAIM_TAX_PERCENTAGE;              // Bears take a 20% tax on all $SALMON claimed
  uint256 public  MAXIMUM_GLOBAL_SALMON;        // there will only ever be (roughly) 2.4 billion $SALMON earned through staking
  uint8   public  MAX_ALPHA; 
  struct ManBear {bool isFisherman; uint8[14] traitarray; uint8 alphaIndex;}

  uint256 public totalSalmonEarned;                                       // amount of $SALMON earned so far
  uint256 public totalFishermanStaked;                                    // number of Fisherman staked in the Riverside
  uint256 public lastClaimTimestamp;                                      // the last time $SALMON was claimed

  bool public rescueEnabled;                                    // emergency rescue to allow unstaking without any checks but without $SALMON


  //Chainlink Setup:
  bytes32 internal keyHash;
  uint256 public fee;
  uint256 internal randomResult;
  uint256 internal randomNumber;
  address public linkToken;
  uint256 public vrfcooldown;
  CountersUpgradeable.Counter public vrfReqd;



  function initialize(address _roar, address _salmon, address _vrfCoordinator, address _link) initializer public {

    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    __VRFConsumerBase_init(_vrfCoordinator,_link);

    roar = Roar(_roar);                                                    // reference to the Roar NFT contract
    salmon = ITSalmon(_salmon);                                                //reference to the $SALMON token

    keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
    fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    linkToken = _link;
    vrfcooldown = 1000;


    totalAlphaStaked = 0;                                    
    unaccountedRewards = 0;                                  
    SalmonPerAlpha = 0;  


    MAXIMUM_GLOBAL_SALMON = 2400000000 ether; 
    MAX_ALPHA = 8; 



    DAILY_SALMON_RATE = 6000 ether;                        // Fisherman earn 10000 $SALMON per day
    MINIMUM_TO_EXIT = 2 days;                               // Fisherman must have 2 days worth of $SALMON to unstake or else it's too cold
    SALMON_CLAIM_TAX_PERCENTAGE = 20; 
    

    rescueEnabled = false; 



  }



  function depositsOf(address account) external view returns (uint256[] memory) {
    if (tx.origin != msg.sender) {
          require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }

    EnumerableSetUpgradeable.UintSet storage depositSet = _deposits[account];
    uint256[] memory tokenIds = new uint256[] (depositSet.length());

    for (uint256 i; i < depositSet.length(); i++) {
      tokenIds[i] = depositSet.at(i);
    }

    return tokenIds;
  }

  // Migrated
  function addManyToRiverSideAndFishing(address account, uint16[] calldata tokenIds) external {    // called in mint

    require(account == _msgSender() || _msgSender() == address(roar), "DONT GIVE YOUR TOKENS AWAY");    

    for (uint i = 0; i < tokenIds.length; i++) {
      uint16 tokenID = tokenIds[i];

      if (_msgSender() != address(roar)) {

        if (tokenID > 10498) {

          require(roar.ownerOf(tokenID) == _msgSender(), "AINT YO TOKEN");
          roar.transferFrom(_msgSender(), address(this), tokenID);

        } else {

          require(genXRoar.ownerOf(tokenID) == _msgSender(), "AINT YO TOKEN");
          genXRoar.transferFrom(_msgSender(), address(this), tokenID);    // Needs Approval

        }
      
      } else if (tokenID == 0) {

        continue; 
      }

      if (isFisherman(tokenID)) 
        _addFishermanToRiverside(account, tokenID);
        
      else 
        _sendBearsFishing(account, tokenID);
    }
  }


  // No need for migration
  function _addFishermanToRiverside(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
    riverside[tokenId] = Stake({
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(block.timestamp)
    });
    totalFishermanStaked += 1;
   
    emit TokenStaked(account, tokenId, block.timestamp);
    _deposits[account].add(tokenId);
  }

  // No need for migration
  function _sendBearsFishing(address account, uint256 tokenId) internal {
    uint256 alpha = _alphaForBear(tokenId);
    totalAlphaStaked += alpha;                                                // Portion of earnings ranges from 8 to 5
    packIndices[tokenId] = Bears[alpha].length;                                // Store the location of the Bear in the Pack
    Bears[alpha].push(Stake({                                                  // Add the Bear to the Pack
      owner: account,
      tokenId: uint16(tokenId),
      value: uint80(SalmonPerAlpha)
    })); 
    emit TokenStaked(account, tokenId, SalmonPerAlpha);
    _deposits[account].add(tokenId);
  }



  // Migrated
  function claimManyFromRiverAndFishing(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant() {
    require(backupclaimethod,"Method Not enabled");
    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    require(tx.origin == _msgSender(), "Only EOA");

    if (tx.origin != msg.sender) {
        require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }
    
    uint256  owed = 0;
    
    for (uint i = 0; i < tokenIds.length; i++) {
      uint16 tokenID = tokenIds[i];
      
      if (tokenID > 10498) 
        require(roar.ownerOf(tokenID) == address(this), "Not Staked here yet."); 
      else 
        require(genXRoar.ownerOf(tokenID) == address(this), "AINT A PART OF THIS"); 
      

      if (isFisherman(tokenID))
        owed += _claimFisherFromRiver(tokenID, unstake);
      else
        owed += _claimBearFromFishing(tokenID, unstake);

    }

    if (owed == 0) return;
    salmon.mint(_msgSender(), owed);


  }


  function claimManyFromRiverAndFishingV2(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant() {

    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    require(tx.origin == _msgSender(), "Only EOA");

    if (tx.origin != msg.sender) {
        require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }
    
    uint256  owed = 0;
    
    for (uint i = 0; i < tokenIds.length; i++) {
      uint16 tokenID = tokenIds[i];
      
      if (tokenID > 10498) {
        // GEN Y NFT
        require(roar.ownerOf(tokenID) == address(this), "Not Staked here yet."); 
        owed +=  _regularclaim(tokenID,unstake);

      } else {
        // GEN X
        if (genXRoar.ownerOf(tokenID) == address(genXStaking)) {
          // OLD STAKING CONTRACT
          owed +=  _claimGenXReward(_msgSender(),tokenID);

        } else {
          // STAKED HERE
          require(genXRoar.ownerOf(tokenID) == address(this), "AINT A PART OF THIS"); 
          owed +=  _regularclaim(tokenID,unstake);
        
        }
      }
    }

    if (owed == 0) return;
    salmon.mint(_msgSender(), owed);


  }

  function _regularclaim(uint256 tokenID, bool unstake) private returns (uint256 owed) {

    if (isFisherman(tokenID))
      owed = _claimFisherFromRiver(tokenID, unstake);
    else
      owed = _claimBearFromFishing(tokenID, unstake);

  } 

  // No need for Migration
  function calculateReward(uint16[] calldata tokenIds) public view returns (uint256 owed) {

    if (tx.origin != msg.sender) {
        require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }

    for (uint i = 0; i < tokenIds.length; i++) {
      if (isFisherman(tokenIds[i]))
        owed += calcRewardFisherman(tokenIds[i]);
      else
        owed +=  calcRewardBear(tokenIds[i]);
    }
  
  }

  // Migrated 
  function calcRewardFisherman(uint256 tokenId) public view returns (uint256 owed) {

    if (tx.origin != msg.sender) {
      require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }

    Stake memory stake = riverside[tokenId];
    uint256 rate;
    if (tokenId > 10498) {
       rate = DAILY_SALMON_RATE;
    } else {
      rate = DAILY_SALMON_RATEGenX;
    }

    if (totalSalmonEarned < MAXIMUM_GLOBAL_SALMON) {
        owed = (block.timestamp - MathUpgradeable.max(resetTime,stake.value) ) * rate / 1 days;

        

    } else if (stake.value > lastClaimTimestamp) {
        owed = 0;

    } else {
        owed = (lastClaimTimestamp - MathUpgradeable.max(resetTime,stake.value)) * rate / 1 days; // stop earning additional $WOOL if it's all been earned
    }

  }

  // No need for Migration - _alphaForBear (Migrated) 
  function calcRewardBear(uint256 tokenId) public view returns (uint256 owed) {

    if (tx.origin != msg.sender) {
        require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }
    uint256 alpha = _alphaForBear(tokenId); 
    Stake memory stake  = Bears[alpha][packIndices[tokenId]];
    owed = (alpha) * ((SalmonPerAlpha - stake.value)-(salmonAlphaReset-stake.value)); 


  }


  // Migrated
  function _claimFisherFromRiver(uint256 tokenId, bool unstake) private returns (uint256 owed) {

    Stake memory stake = riverside[tokenId];

    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S WOOL");

    owed = calcRewardFisherman(tokenId);

    if (unstake) {

      if (random(tokenId) & 1 == 1) {                                           // 50% chance of all $SALMON stolen
        _payBearTax(owed);
        owed = 0;  
      }
      
      delete riverside[tokenId];
      totalFishermanStaked -= 1;
      _deposits[_msgSender()].remove(tokenId);


      if (tokenId > 10498) {
        roar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman 
      } else {
        genXRoar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman 
      }
             
    } else {

      _payBearTax(owed * SALMON_CLAIM_TAX_PERCENTAGE / 100);                    // percentage tax to staked Bears    
      riverside[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
      }); // reset stake
      owed = owed * (100 - SALMON_CLAIM_TAX_PERCENTAGE) / 100;                  // remainder goes to Fisherman owner
    }
    emit FishermanClaimed(tokenId, owed, unstake);
  }


  // Migrated
  function _claimBearFromFishing(uint256 tokenId, bool unstake) private returns (uint256 owed) {

    uint256 alpha = _alphaForBear(tokenId);  
    Stake memory stake = Bears[alpha][packIndices[tokenId]];         
    require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");

    owed = calcRewardBear(tokenId);                                         // Calculate portion of tokens based on Alpha

    if (unstake) {
      totalAlphaStaked -= alpha;                                            // Remove Alpha from total staked
      Stake memory lastStake = Bears[alpha][Bears[alpha].length - 1];         // Shuffle last Bear to current position PT 1 
      Bears[alpha][packIndices[tokenId]] = lastStake;                        // Shuffle last Bear to current position PT 2
      packIndices[lastStake.tokenId] = packIndices[tokenId];                // Shuffle last Bear to current position PT 3
      Bears[alpha].pop();                                                    // Remove duplicate

      delete packIndices[tokenId];                                          // Delete old mapping
      _deposits[_msgSender()].remove(tokenId);

      if (tokenId > 10498) {
        roar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman 
      } else {
        genXRoar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman 
      }   


    } else {

      Bears[alpha][packIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        value: uint80(SalmonPerAlpha)
      }); // reset stake

    }
    emit BearClaimed(tokenId, owed, unstake);
  }

  // NOT YET MIGRATED
  function rescue(uint256[] calldata tokenIds) external nonReentrant() {
    require(!_msgSender().isContract(), "Contracts are not allowed big man");
    require(tx.origin == _msgSender(), "Only EOA");
    require(rescueEnabled, "RESCUE DISABLED");
    
    

    uint256 tokenId;
    Stake memory stake;
    Stake memory lastStake;
    uint256 alpha;

    for (uint i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];
      if (tokenId > 10498) 
        require(roar.ownerOf(tokenId) == address(this), "Not Staked here yet."); 
      else 
        require(genXRoar.ownerOf(tokenId) == address(this), "AINT A PART OF THIS"); 
      
      if (isFisherman(tokenId)) {
        stake = riverside[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        delete riverside[tokenId];
        totalFishermanStaked -= 1;

        if (tokenId > 10498) {
          roar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman 
        } else {
          genXRoar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman 
        }

        emit FishermanClaimed(tokenId, 0, true);

      } else {
        alpha = _alphaForBear(tokenId);
        stake = Bears[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        totalAlphaStaked -= alpha; // Remove Alpha from total staked
        lastStake = Bears[alpha][Bears[alpha].length - 1];
        Bears[alpha][packIndices[tokenId]] = lastStake; // Shuffle last bear to current position
        packIndices[lastStake.tokenId] = packIndices[tokenId];
        Bears[alpha].pop(); // Remove duplicate
        delete packIndices[tokenId]; // Delete old mapping

        if (tokenId > 10498) {
          roar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman 
        } else {
          genXRoar.safeTransferFrom(address(this), _msgSender(), tokenId, "");         // send back Fisherman 
        }  

        emit BearClaimed(tokenId, 0, true);
      }
    }
  }

  /** ACCOUNTING */

  // No Need for Migration
  function _payBearTax(uint256 amount) private {

    if (totalAlphaStaked == 0) {                                              // if there's no staked Bear > keep track of $SALMON due to Bear
      unaccountedRewards += amount; 
      return;
    }

    SalmonPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;         // makes sure to include any unaccounted $SALMON
    unaccountedRewards = 0;
  }

  modifier _updateEarnings() {

    if (totalSalmonEarned < MAXIMUM_GLOBAL_SALMON) {
      totalSalmonEarned += 
        (block.timestamp - lastClaimTimestamp)
        * totalFishermanStaked
        * DAILY_SALMON_RATE / 1 days; 
      lastClaimTimestamp = block.timestamp;
    }
    _;
  }

  function setWhitelistContract(address contract_address, bool status) public onlyOwner{
    whitelistedContracts[contract_address] = status;
  }

  // Migrated
  function isFisherman(uint256 tokenId) public view returns (bool fisherman) {

    if (tx.origin != msg.sender) {
        require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }

    if (tokenId > 10498) {
      Roar.ManBear memory yo = roar.getTokenTraits(tokenId);
      return yo.isFisherman;
    } else {

      (fisherman,  ) = genXRoar.tokenTraits(tokenId);
      return fisherman;
    }

  }
  // Migrated                             
  function _alphaForBear(uint256 tokenId) private view returns (uint8) {

    if (tokenId > 10498) {
      Roar.ManBear memory yo = roar.getTokenTraits(tokenId);
      return MAX_ALPHA - yo.alphaIndex; 
    } else {

      GenXInterface.ManBear memory yo = genXRoarInterface.getTokenTraits(tokenId);
      return MAX_ALPHA - yo.alphaIndex; 
    }
  }

  // Shouldnt need migration if we use same bear array for both genX and genY
  function randomBearOwner(uint256 seed) external view returns (address) {

    if (tx.origin != msg.sender) {
      require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }

    if (totalAlphaStaked == 0) return address(0x0);

    uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked;                  // choose a value from 0 to total alpha staked
    uint256 cumulative;
    seed >>= 32;

    for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {                     // loop through each bucket of Bears with the same alpha score
      cumulative += Bears[i].length * i;
      if (bucket >= cumulative) continue;                                   // if the value is not inside of that bucket, keep going

      return Bears[i][seed % Bears[i].length].owner;                          // get the address of a random Bear with that alpha score
    }

    return address(0x0);
  }

  /** CHANGE PARAMETERS */


  function setInit(address _roar, address _salmon) external onlyOwner{
    roar = Roar(_roar);                                              
    salmon = ITSalmon(_salmon);                                               

  }

  function changeDailyRateGenY(uint256 _newRate) external onlyOwner{
      DAILY_SALMON_RATE = _newRate;
  }
  
  function changeDailyRateGenX(uint256 _newRate) external onlyOwner{
      DAILY_SALMON_RATEGenX = _newRate;
  }

  function changeMinExit(uint256 _newExit) external onlyOwner{
      MINIMUM_TO_EXIT = _newExit ;
  }

  function changeSalmonTax(uint256 _newTax) external onlyOwner {
      SALMON_CLAIM_TAX_PERCENTAGE = _newTax;
  }


  function changeMaxSalmon(uint256 _newMax) external onlyOwner {
      MAXIMUM_GLOBAL_SALMON = _newMax;
  }

  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }
  
        
  /** RANDOMNESSSS */

  function changeLinkFee(uint256 _fee) external onlyOwner {
    // fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    fee = _fee;
  }

  function random(uint256 seed) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      tx.origin,
      blockhash(block.number - 1),
      block.timestamp,
      seed,
      randomNumber
    )));
  }

  function initChainLink() external onlyOwner {
      vrfReqd.increment();
      getRandomChainlink();
  }

  function getRandomChainlink() private returns (bytes32 requestId) {

    if (tx.origin != msg.sender) {
        require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }

    if (vrfReqd.current() <= vrfcooldown) {
      vrfReqd.increment();
      return 0x000;
    }

    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    vrfReqd.reset();
    return requestRandomness(keyHash, fee);
  }

  function changeVrfCooldown(uint256 _cooldown) external onlyOwner{
      vrfcooldown = _cooldown;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
      bytes32 reqId = requestId;
      randomNumber = randomness;
  }

  function withdrawLINK() external onlyOwner {
    uint256 tokenSupply = IERC20Upgradeable(linkToken).balanceOf(address(this));
    IERC20Upgradeable(linkToken).transfer(msg.sender, tokenSupply);
  }

  function changeLinkAddress(address _newaddress) external onlyOwner{
      linkToken = _newaddress;
  }
   
 
  /** OTHERS  */
  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
    require(from == address(0x0), "Cannot send tokens to Barn directly");
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  /** RESET EDITION */
                                                                                        
  uint256 public  DAILY_SALMON_RATEGenX;

  mapping(uint256 => bool) public migrated;    
  uint256 public resetTime;

  
  

  RoarGenX genXRoar; 
  RiverGenX genXStaking;
  GenXInterface genXRoarInterface;

  function setGenXContract(address _staking,address  _mint) external onlyOwner {
    genXStaking = RiverGenX(_staking);
    genXRoar = RoarGenX(_mint);
    genXRoarInterface = GenXInterface(_mint);
    DAILY_SALMON_RATEGenX = 10000 ether; 
    backupclaimethod = false;
  }

  function claimGenXRewards (address account, uint16[] calldata tokenIds) external whenNotPaused _updateEarnings nonReentrant() {
    require(backupclaimethod,"Method Not enabled");
    _claimGenXRewards(account,tokenIds);  
  }
   
  function _claimGenXRewards(address account, uint16[] calldata tokenIds) private  {
    require(backupclaimethod,"Method Not enabled");
    require(account == _msgSender() && !_msgSender().isContract(), "Contracts are not allowed big man");

    if (tx.origin != msg.sender) {
      require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }
    
    bool unstake = false;
    uint256  owed = 0;
        
    for (uint i = 0; i < tokenIds.length; i++) {
      
      uint16 tokenID = tokenIds[i];

      require(tokenID <= 10498, "Not a Gen X Token");
      require(genXRoar.ownerOf(tokenID) == address(genXStaking), "AINT A PART OF THE OLD CONTRACT"); 

      bool fisherman = isFisherman(tokenID);
      
      if (!migrated[tokenID]) {
          // Token hasnt migrated yet - aka claiming for the first time.
          if (fisherman) {

            uint16 tokenId;
            uint80 valueOLD;
            address owner;
              
            (tokenId,valueOLD,owner) = genXStaking.riverside(tokenID);
            require(owner == _msgSender(), "Not your token bro");

            // Calculate rewards
            uint80 value = uint80(MathUpgradeable.min(block.timestamp,resetTime));
            owed = calcFishermanSalmonGenX(value);
            _payBearTax(owed * SALMON_CLAIM_TAX_PERCENTAGE / 100);                    
            owed = owed * (100 - SALMON_CLAIM_TAX_PERCENTAGE) / 100;     

            // simulate adding fisherman to current contract
            riverside[tokenID] = Stake({owner: _msgSender(), tokenId: uint16(tokenID), value: uint80(block.timestamp)}); 
            migrated[tokenID] = true;

            emit FishermanClaimed(tokenID, owed, unstake);
            emit TokenStaked(account, tokenID, block.timestamp);


          
          } else {

            uint256 alpha = _alphaForBear(tokenID);  
            uint16 tokenId;
            uint80 value;
            address owner;
            uint256 indic = genXStaking.packIndices(tokenID);
            (tokenId,value,owner) = genXStaking.Bears(alpha,indic);        
            require(owner == _msgSender(), "SWIPER, NO SWIPING");


            // Calculate rewards
            owed = (alpha) * (SalmonPerAlpha - 0)
            
            ; 

            // simulate adding bear to current contract
            totalAlphaStaked += alpha; 
            packIndices[tokenID] = Bears[alpha].length;
            Bears[alpha].push(Stake({owner: account,tokenId: uint16(tokenID),value: uint80(0)})); 

            migrated[tokenID] = true;


              
            emit TokenStaked(account, tokenID, SalmonPerAlpha);

          }

      } else {

          if (fisherman) {

              Stake memory stake = riverside[tokenID];
              owed = calcFishermanSalmonGenX(stake.value);
              _payBearTax(owed * SALMON_CLAIM_TAX_PERCENTAGE / 100);        
              riverside[tokenID] = Stake({owner: _msgSender(), tokenId: uint16(tokenID), value: uint80(block.timestamp)}); 
              owed = owed * (100 - SALMON_CLAIM_TAX_PERCENTAGE) / 100;     
              emit FishermanClaimed(tokenID, owed, unstake);

          } else {
              
              owed = calcRewardBear(tokenID); 
              uint256 alpha = _alphaForBear(tokenID);  
              Bears[alpha][packIndices[tokenID]] = Stake({owner: _msgSender(),tokenId: uint16(tokenID),value: uint80(SalmonPerAlpha)}); // reset stake

          }

      }
      
  
      if (owed == 0) return;
      salmon.mint(_msgSender(), owed);
    }

  }

  function _claimGenXReward(address account, uint16 tokenID) private returns (uint256 owed) {
    
    require(tokenID <= 10498, "Not a Gen X Token");
    require(account == _msgSender() && !_msgSender().isContract(), "Contracts are not allowed big man");
    require(genXRoar.ownerOf(tokenID) == address(genXStaking), "AINT A PART OF THE OLD CONTRACT"); 

    if (tx.origin != msg.sender) {
      require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
    }
    
    bool unstake = false;
    owed = 0;
    bool fisherman = isFisherman(tokenID);
    
    if (!migrated[tokenID]) {
        // Token hasnt migrated yet - aka claiming for the first time.
        if (fisherman) {

          uint16 tokenId;
          uint80 valueOLD;
          address owner;
            
          (tokenId,valueOLD,owner) = genXStaking.riverside(tokenID);
          require(owner == _msgSender(), "Not your token bro");

          // Calculate rewards
          uint80 value = uint80(MathUpgradeable.min(block.timestamp,resetTime));
          owed = calcFishermanSalmonGenX(value);
          _payBearTax(owed * SALMON_CLAIM_TAX_PERCENTAGE / 100);                    
          owed = owed * (100 - SALMON_CLAIM_TAX_PERCENTAGE) / 100;     

          // simulate adding fisherman to current contract
          riverside[tokenID] = Stake({owner: _msgSender(), tokenId: uint16(tokenID), value: uint80(block.timestamp)}); 
          migrated[tokenID] = true;

          emit FishermanClaimed(tokenID, owed, unstake);
          emit TokenStaked(account, tokenID, block.timestamp);


        
        } else {

          uint256 alpha = _alphaForBear(tokenID);  
          uint16 tokenId;
          uint80 value;
          address owner;
          uint256 indic = genXStaking.packIndices(tokenID);
          (tokenId,value,owner) = genXStaking.Bears(alpha,indic);        
          require(owner == _msgSender(), "SWIPER, NO SWIPING");


          // Calculate rewards
          owed = (alpha) * (SalmonPerAlpha - salmonAlphaReset); 

          // simulate adding bear to current contract
          totalAlphaStaked += alpha; 
          packIndices[tokenID] = Bears[alpha].length;
          Bears[alpha].push(Stake({owner: account,tokenId: uint16(tokenID),value: uint80(0)})); 

          migrated[tokenID] = true;


            
          emit TokenStaked(account, tokenID, SalmonPerAlpha);

        }

    } else {

        if (fisherman) {

            Stake memory stake = riverside[tokenID];
            owed = calcFishermanSalmonGenX(stake.value);
            _payBearTax(owed * SALMON_CLAIM_TAX_PERCENTAGE / 100);        
            riverside[tokenID] = Stake({owner: _msgSender(), tokenId: uint16(tokenID), value: uint80(block.timestamp)}); 
            owed = owed * (100 - SALMON_CLAIM_TAX_PERCENTAGE) / 100;     
            emit FishermanClaimed(tokenID, owed, unstake);

        } else {
            
            owed = calcRewardBear(tokenID); 
            uint256 alpha = _alphaForBear(tokenID);  
            Bears[alpha][packIndices[tokenID]] = Stake({owner: _msgSender(),tokenId: uint16(tokenID),value: uint80(SalmonPerAlpha)}); // reset stake

        }

    }
    

    // if (owed == 0) return;
    // salmon.mint(_msgSender(), owed);

    return owed;
  

  }

  function calcFishermanSalmonGenX(uint80 value) internal view returns (uint256 owed) {

      if (tx.origin != msg.sender) {
        require(whitelistedContracts[msg.sender], "You're not allowed to call this function");
      }

      if (totalSalmonEarned < MAXIMUM_GLOBAL_SALMON) {
          owed = (block.timestamp - value) * DAILY_SALMON_RATEGenX / 1 days;

      } else if (value > lastClaimTimestamp) {
          owed = 0; 

      } else {
          owed = (lastClaimTimestamp - value) * DAILY_SALMON_RATEGenX / 1 days; 
      }

  }

  function setResetTime(uint256 _time) external onlyOwner {
    resetTime = _time;
  }

  function enableBackupClaim (bool _status) external onlyOwner {
    backupclaimethod = _status;
    
  }

  bool public backupclaimethod;

  uint256 public salmonAlphaReset;


  function setAlphaReset(uint256 _new) external onlyOwner{

    salmonAlphaReset = _new;


  }

  
}