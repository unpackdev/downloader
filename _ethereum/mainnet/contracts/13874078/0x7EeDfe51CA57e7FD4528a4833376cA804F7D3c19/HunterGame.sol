// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Mintor.sol";
import "./Forest.sol";
import "./Prey.sol";
import "./HunterHound.sol";



contract HunterGame is Mintor, Forest, Ownable {


  // swtich to turn on/off the game
  bool _paused = true;

  // 111 take back staked tokens using rescue() function in rescue mode, rescue mode happens when the code turns buggy
  bool _rescueEnabled = false;

  // switch to turn on/off the whitelist
  bool public _whitelistEnabled = true;

  // mapping from an address to whether or not it can mint
  mapping(address => bool) public _whitelist;

  // maximum number of tokens for each participant in the whitelist can mint
  uint public _whitelistMintLimit = 5;

  // record number of tokens a whitelisted address minted
  mapping(address => uint) public _whitelistMinted;

  // ERC20 contract
  Prey public prey;

  // ERC721 contract
  HunterHound public hunterHound;

  constructor(address prey_, address hunterHound_, address[] memory whitelist_) {
    prey = Prey(prey_);

    hunterHound = HunterHound(hunterHound_);

    for (uint256 i = 0; i < whitelist_.length; i++) {
      _whitelist[whitelist_[i]] = true;
    }
  }

  /**
   * return main information of the game
   */
  function getGameStatus() public view 
  returns(
    bool paused, uint phase, uint minted, uint requested,
    uint hunterMinted, uint houndMinted, 
    uint hunterStaked, uint houndStaked,
    uint totalClaimed, uint totalBurned,
    uint houndsCaptured, uint maxTokensByCurrentPhase ) {
      paused = _paused;
      phase = currentPhase();
      minted = Mintor.minted;
      requested = Mintor.requested;
      hunterMinted = Mintor.hunterMinted;
      houndMinted = minted - hunterMinted;
      hunterStaked = Forest.hunterStaked;
      houndStaked = Forest.houndStaked;
      totalClaimed = Forest.totalClaimed;
      totalBurned = Forest.totalBurned;
      houndsCaptured = Forest.houndsCaptured;
      maxTokensByCurrentPhase = currentPhaseAmount();
  }

  /**
   * return phase number of the game by recorded mint requests
   */
  function currentPhase() public view returns(uint p) {
    uint[4] memory amounts = [PHASE1_AMOUNT,PHASE2_AMOUNT,PHASE3_AMOUNT,PHASE4_AMOUNT];
    for (uint i = 0; i < amounts.length; i++) {
      p += amounts[i];
      if (requested < p) {
        return i+1;
      }
    }
  }

  /**
   * get target total number of mints in current phase by recorded mint requests
   */
  function currentPhaseAmount() public view returns(uint p) {
    uint[4] memory amounts = [PHASE1_AMOUNT,PHASE2_AMOUNT,PHASE3_AMOUNT,PHASE4_AMOUNT];
    for (uint256 i = 0; i < amounts.length; i++) {
      p += amounts[i];
      if (requested < p) {
        return p;
      }
    }
  }

  /**
   * check whether the address has enough ETH or $PREY balance to mint in the wallet and validity of the number of mints
   */
  function mintPrecheck(uint amount) private {
    uint phaseAmount = currentPhaseAmount();
    // make sure preciseness of mints in every phase
    require(amount > 0 && amount <= 20 && (requested % phaseAmount) <= ((requested + amount - 1) % phaseAmount) , "Invalid mint amount");
    require(requested + amount <= MAX_TOKENS, "All tokens minted");
    uint phase = currentPhase();
    if (phase == 1) {
      require(msg.value == MINT_PRICE * amount, "Invalid payment amount");
    } else {
      require(msg.value == 0, "Only prey");
      uint totalMintCost;
      if (phase == 2) {
        totalMintCost = MINT_PHASE2_PRICE;
      } else if (phase == 3) {
        totalMintCost = MINT_PHASE3_PRICE;
      } else {
        totalMintCost = MINT_PHASE4_PRICE;
      }
      
      prey.burn(msg.sender, totalMintCost * amount);
    }
  }
  

  /************** MINTING **************/

  
  /**
   * security check and execute `Mintor._request()` function
   */
  function requestMint(uint amount) external payable {
    require(tx.origin == msg.sender, "No Access");
    if (_paused) {
      require(_whitelistEnabled, 'Paused');
      require(_whitelist[msg.sender] && _whitelistMinted[msg.sender] + amount <= _whitelistMintLimit, "Only Whitelist");
      _whitelistMinted[msg.sender] += amount;
    }
    mintPrecheck(amount);

    Mintor._request(msg.sender, amount);
  }

  /**
   * security check and execute `Mintor._receive()` function
   */
  function mint() external {
    require(tx.origin == msg.sender, "No Access");
    
    Mintor._receive(msg.sender, hunterHound);
  }

  /**
   * execute `Mintor._mintRequestState()` function
   */
  function mintRequestState(address requestor) external view returns (uint blockNumber, uint amount, uint state, uint open, uint timeout) {
    return _mintRequestState(requestor);
  }

  /************** Forest **************/

  /**
   * return all holders' stake history
   */
  function stakesByOwner(address owner) external view returns(Stake[] memory) {
    return stakes[owner];
  }

  /**
   * security check and execute `Forest._stake()` function
   */
  function stakeToForest(uint256[][] calldata paris) external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    
    Forest._stake(msg.sender, paris, hunterHound);
  }

  /**
   * security check and execute `Forest._claim()` function
   */
  function claimFromForest() external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    
    Forest._claim(msg.sender, prey);
    
  }

  /**
   * security check and execute `Forest._requestGamble()` function
   */
  function requestGamble(uint action) external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    Forest._requestGamble(msg.sender, action);
  }

  /**
   * 执行 `Forest._gambleRequestState()` 
   */
  function gambleRequestState(address requestor) external view returns (uint blockNumber, uint action, uint state, uint open, uint timeout) {
    return Forest._gambleRequestState(requestor);
  }

  /**
   * security check and execute `Forest._unstake()` function
   */
  function unstakeFromForest() external whenNotPaused {
    require(tx.origin == msg.sender, "No Access");
    Forest._unstake(msg.sender, prey, hunterHound);
  }

  /**
   * security check and execute `Forest._rescue()` function
   */
  function rescue() external {
    require(tx.origin == msg.sender, "No Access");
    require(_rescueEnabled, "Rescue disabled");
    Forest._rescue(msg.sender, hunterHound);
  }

  /************** ADMIN **************/

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance available");
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * when the game is not paused
   */
  modifier whenNotPaused() {
      require(_paused == false, "Pausable: paused");
      _;
  }

  /**
   * pause/run the game
   */
  function setPaused(bool paused_) external onlyOwner {
    _paused = paused_;
  }

  /**
   * turn on/off rescue mode
   */
  function setRescueEnabled(bool rescue_) external onlyOwner {
    _rescueEnabled = rescue_;
  }
  
  /**
   * turn on/off whitelist
   */
  function setWhitelistEnabled(bool whitelistEnabled_) external onlyOwner {
    _whitelistEnabled = whitelistEnabled_;
  }

  /**
   * set maximum minting limit for each address in whitelist
   */
  function setWhitelistMintLimit(uint whitelistMintLimit_) external onlyOwner {
    _whitelistMintLimit = whitelistMintLimit_;
  }

  /**
   * add/delete whitelist
   */
  function setWhitelist(address[] calldata whitelist_, bool b) external onlyOwner {
    for (uint256 i = 0; i < whitelist_.length; i++) {
      _whitelist[whitelist_[i]] = b;
    }
  }


}
