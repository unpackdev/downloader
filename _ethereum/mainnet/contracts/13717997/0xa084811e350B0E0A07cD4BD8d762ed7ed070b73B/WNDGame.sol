// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./IWnDGame.sol";
import "./ITower.sol";
import "./ITraits.sol";
import "./IGP.sol";
import "./IWnD.sol";
import "./ISacrificialAlter.sol";
import "./IRandomizer.sol";


contract WnDGame is IWnDGame, Ownable, ReentrancyGuard, Pausable {

  IRandomizer public randomizer; 

  struct LastWrite {
    uint64 time;
    uint64 blockNum;
  }

  struct Whitelist {
    bool isWhitelisted;
    uint16 numMinted;
  }

  mapping(address => LastWrite) private _lastWrite;

  bool public hasPublicSaleStarted;
  uint256 public presalePrice = 0.088 ether;
  uint256 public treasureChestTypeId;

  uint256 private maxPrice = 0.42069 ether;
  // uint256 private maxPrice = 0.0001 ether;
  uint256 private minPrice = 0.088 ether;
  // uint256 private minPrice = 0.0001 ether;
  uint256 private priceDecrementAmt = 0.01 ether;
  uint256 private timeToDecrementPrice = 10 minutes;
  uint256 private startedTime;
  // max $GP cost 
  uint256 private maxGpCost = 72000 ether;

  mapping(address => Whitelist) private _whitelistAddresses;

  // reference to the Tower for choosing random Dragon thieves
  ITower public tower;
  // reference to $GP for burning on mint
  IGP public gpToken;
  // reference to Traits
  ITraits public traits;
  // reference to NFT collection
  IWnD public wndNFT;
  // reference to alter collection
  ISacrificialAlter public alter;

  /** 
   * instantiates contract and rarity tables
   */
  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(gpToken) != address(0) && address(traits) != address(0) 
        && address(wndNFT) != address(0) && address(tower) != address(0) && address(alter) != address(0)
         && address(randomizer) != address(0)
        , "Contracts not set");
      _;
  }

  function setContracts(address _gp, address _traits, address _wnd, address _tower, address _alter, address _rand) external onlyOwner {
    gpToken = IGP(_gp);
    traits = ITraits(_traits);
    wndNFT = IWnD(_wnd);
    tower = ITower(_tower);
    alter = ISacrificialAlter(_alter);
    randomizer = IRandomizer(_rand);
  }

  function setTreasureChestId(uint256 typeId) external onlyOwner {
    treasureChestTypeId = typeId;
  }
  /** EXTERNAL */

  /** 
   * mint a token - 90% Wizard, 10% Dragons
   * The first 25% are claimed with eth, the remaining cost $GP
   */
  function mint(uint256 amount, bool stake) external payable whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    uint16 minted = wndNFT.minted();
    uint256 maxTokens = wndNFT.getMaxTokens();
    uint256 paidTokens = wndNFT.getPaidTokens();
    require(minted + amount <= maxTokens, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");
    if (minted < paidTokens) {
      require(minted + amount <= paidTokens, "All tokens on-sale already sold");
      if(hasPublicSaleStarted) {
        require(msg.value >= amount * currentPriceToMint(), "Invalid payment amount");
      }
      else {
        require(amount * presalePrice == msg.value, "Invalid payment amount");
        require(_whitelistAddresses[_msgSender()].isWhitelisted, "Not on whitelist");
        require(_whitelistAddresses[_msgSender()].numMinted + amount <= 2, "too many mints");
        _whitelistAddresses[_msgSender()].numMinted += uint16(amount);
      }
    } else {
      require(msg.value == 0);
    }
    LastWrite storage lw = _lastWrite[tx.origin];

    uint256 totalGpCost = 0;
    uint16[] memory tokenIds = new uint16[](amount);
    uint256 seed = 0;
    for (uint i = 0; i < amount; i++) {
      minted++;
      seed = randomizer.random();
      address recipient = selectRecipient(seed, minted, paidTokens);
      if(recipient != _msgSender() && alter.balanceOf(_msgSender(), treasureChestTypeId) > 0) {
        // If the mint is going to be stolen, there's a 50% chance 
        //  a dragon will prefer a treasure chest over it
        if(seed & 1 == 1) {
          alter.safeTransferFrom(_msgSender(), recipient, treasureChestTypeId, 1, "");
          recipient = _msgSender();
        }
      }
      tokenIds[i] = minted;
      if (!stake || recipient != _msgSender()) {
        wndNFT.mint(recipient, seed);
      } else {
        wndNFT.mint(address(tower), seed);
      }
      totalGpCost += mintCost(minted, maxTokens, paidTokens);
    }
    wndNFT.updateOriginAccess(tokenIds);
    if (totalGpCost > 0) {
      gpToken.burn(_msgSender(), totalGpCost);
      gpToken.updateOriginAccess();
    }
    if (stake) {
      tower.addManyToTowerAndFlight(_msgSender(), tokenIds);
    }
    lw.time = uint64(block.timestamp);
    lw.blockNum = uint64(block.number);
  }

  function currentPriceToMint() view public returns(uint256) {
    uint256 numDecrements = (block.timestamp - startedTime) / timeToDecrementPrice;
    uint256 decrementAmt = (priceDecrementAmt * numDecrements);
    if(decrementAmt > maxPrice) {
      return minPrice;
    }
    uint256 adjPrice = maxPrice - decrementAmt;
    return adjPrice;
  }

  function addToWhitelist(address[] calldata addressesToAdd) public onlyOwner {
    for (uint256 i = 0; i < addressesToAdd.length; i++) {
      _whitelistAddresses[addressesToAdd[i]] = Whitelist(true, 0);
    }
  }

  function setPublicSaleStart(bool started) external onlyOwner {
    hasPublicSaleStarted = started;
    if(hasPublicSaleStarted) {
      startedTime = block.timestamp;
    }
  }

  /** 
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId, uint256 maxTokens, uint256 paidTokens) public view returns (uint256) {
    if (tokenId <= paidTokens) return 0;
    if (tokenId <= maxTokens * 8 / 20) return 24000 ether;
    if (tokenId <= maxTokens * 11 / 20) return 36000 ether;
    if (tokenId <= maxTokens * 14 / 20) return 48000 ether;
    if (tokenId <= maxTokens * 17 / 20) return 60000 ether; 
    if (tokenId > maxTokens * 17 / 20) return maxGpCost;
  }

  function payTribute(uint256 gpAmt) external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    uint16 minted = wndNFT.minted();
    uint256 maxTokens = wndNFT.getMaxTokens();
    uint256 paidTokens = wndNFT.getPaidTokens();
    uint256 gpMintCost = mintCost(minted, maxTokens, paidTokens);
    require(gpMintCost > 0, "Sacrificial alter currently closed");
    require(gpAmt >= gpMintCost, "Not enough gp given");
    gpToken.burn(_msgSender(), gpAmt);
    if(gpAmt < gpMintCost * 2) {
      alter.mint(1, 1, _msgSender());
    }
    else {
      alter.mint(2, 1, _msgSender());
    }
  }

  function makeTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    require(treasureChestTypeId > 0, "DEVS DO SOMETHING");
    // $GP exchange amount handled within alter contract
    // Will fail if sender doesn't have enough $GP
    // Transfer does not need approved,
    //  as there is established trust between this contract and the alter contract 
    alter.mint(treasureChestTypeId, qty, _msgSender());
  }

  function sellTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    require(treasureChestTypeId > 0, "DEVS DO SOMETHING");
    // $GP exchange amount handled within alter contract
    alter.burn(treasureChestTypeId, qty, _msgSender());
  }

  function sacrifice(uint256 tokenId, uint256 gpAmt) external whenNotPaused nonReentrant {
    require(tx.origin == _msgSender(), "Only EOA");
    uint64 lastTokenWrite = wndNFT.getTokenWriteBlock(tokenId);
    // Must check this, as getTokenTraits will be allowed since this contract is an admin
    require(lastTokenWrite < block.number, "hmmmm what doing?");
    IWnD.WizardDragon memory nft = wndNFT.getTokenTraits(tokenId);
    uint16 minted = wndNFT.minted();
    uint256 maxTokens = wndNFT.getMaxTokens();
    uint256 paidTokens = wndNFT.getPaidTokens();
    uint256 gpMintCost = mintCost(minted, maxTokens, paidTokens);
    require(gpMintCost > 0, "Sacrificial alter currently closed");
    if(nft.isWizard) {
      // Wizard sacrifice requires 3x $GP curve
      require(gpAmt >= gpMintCost * 3, "not enough gp provided");
      gpToken.burn(_msgSender(), gpAmt);
      // This will check if origin is the owner of the token
      wndNFT.burn(tokenId);
      alter.mint(3, 1, _msgSender());
    }
    else {
      // Dragon sacrifice requires 4x $GP curve
      require(gpAmt >= gpMintCost * 4, "not enough gp provided");
      gpToken.burn(_msgSender(), gpAmt);
      // This will check if origin is the owner of the token
      wndNFT.burn(tokenId);
      alter.mint(4, 1, _msgSender());
    }
  }

  /** INTERNAL */

  /**
   * the first 25% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked dragon
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Dragon thief's owner)
   */
  function selectRecipient(uint256 seed, uint256 minted, uint256 paidTokens) internal view returns (address) {
    if (minted <= paidTokens || ((seed >> 245) % 10) != 0) return _msgSender(); // top 10 bits haven't been used
    address thief = tower.randomDragonOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0)) return _msgSender();
    return thief;
  }

  /** ADMIN */

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setMaxGpCost(uint256 _amount) external requireContractsSet onlyOwner {
    maxGpCost = _amount;
  } 

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}