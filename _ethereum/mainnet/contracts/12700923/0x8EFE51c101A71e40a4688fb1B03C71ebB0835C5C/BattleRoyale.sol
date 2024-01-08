// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./ERC721Tradable.sol";
import "./AddressArray.sol";
import "./Uint256Array.sol";
import "./BattleRoyaleArena.sol";

contract BattleRoyale is ERC721Tradable {
  using AddressArray for AddressArray.Addresses;
  using Uint256Array for Uint256Array.Uint256s;
  // Structure of token data on chain
  struct NFTRoyale {
    bool inPlay;
    uint256 placement;
  }
  // Maximum number of mintable tokens
  uint256 public maxSupply = 0;
  // current purchasable units per transaction
  uint256 public unitsPerTransaction;
  // Prize token URI to be set to winner
  string public prizeTokenURI;
  // Prize token URI to be set to winner
  string public defaultTokenURI;
  //  time in minutes
  uint256 public intervalTime;
  // timestamp of last elimination
  uint256 public timestamp;
  // initial price per token
  uint256 public price;
  // Current game state
  enum BATTLE_STATE {
    STANDBY,
    RUNNING,
    ENDED
  }
  BATTLE_STATE public battleState;
  // Look into elimination logic and how to maintain state of all NFTs in and out of play
  Uint256Array.Uint256s inPlay;
  Uint256Array.Uint256s outOfPlay;
  // Array of purchaser addresses
  AddressArray.Addresses purchasers;
  // Temp mapping for NFTs awaiting game execution
  mapping(uint256 => NFTRoyale) public nftRoyales;
  // set to true when wanting the game to start automatically once sales hit max supply
  bool public autoStart;
  // set to true when wanting the game to start automatically once sales hit max supply
  bool public autoPayout;
  // Address of the artist
  address payable public artist;
  address payable public delegate;
  // Set rate
  uint256 public feeRate;

  /*
   * constructor
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _price,
    uint256 _units,
    uint256 _supply,
    bool _autoStart,
    bool _autoPayout,
    address payable _delegate
  )
  public ERC721Tradable(
    _name,
    _symbol,
    'https://ipfs.io/ipfs/'
  ) {
    battleState = BATTLE_STATE.STANDBY;
    intervalTime = 30;
    price = _price;
    unitsPerTransaction = _units;
    maxSupply = _supply;
    autoStart = _autoStart;
    autoPayout = _autoPayout;
    delegate = _delegate;
  }
  /*
   * Mint NFTs
   */
  function purchase(uint256 units) external payable {
    require(price > 0);
    require(battleState == BATTLE_STATE.STANDBY);
    require(maxSupply > 0 && totalSupply() < maxSupply);
    require(units <= maxSupply - totalSupply());
    require(units > 0 && units <= unitsPerTransaction);
    require(bytes(defaultTokenURI).length > 0);
    require(msg.value >= (price * units));
    require(purchasers.getIndex(msg.sender) < 0, "Only 1 purchase per account.");
    // add buyer address to list
    purchasers.push(msg.sender);

    for (uint256 i = 0; i < units; i++) {
      uint256 tokenId = mintTo(msg.sender);
      _setTokenURI(tokenId, defaultTokenURI);
      inPlay.push(tokenId);
      nftRoyales[tokenId] = NFTRoyale({
        inPlay: true,
        placement: 0
      });
    }

    // Begin battle if max supply has been reached
    if (maxSupply == totalSupply() && autoStart) {
      startBattle();
    }
  }

  /*
   * Burn method
   * @param  {[type]} uint256 [description]
   * @return {[type]}         [description]
   */
  function burn(uint256 _tokenId) public virtual {
    require(msg.sender == ownerOf(_tokenId) || msg.sender == delegate || msg.sender == owner());
    delete nftRoyales[_tokenId];
    inPlay.remove(_tokenId);
    _burn(_tokenId);
  }
  /* ==========================
   * BATTLE ROYALE METHODS
   * ========================== */
  /*
   * Method to withdraw ETH
   */
   function withdraw(uint256 amount) external override virtual {
     require(msg.sender == delegate || msg.sender == owner());
     uint256 balance = address(this).balance;
     require(amount <= balance);
     if (delegate != address(0)) {
       payable(delegate).transfer(amount);
     } else {
       msg.sender.transfer(amount);
     }
   }
  /*
  * Get Current ETH Balance from contract
  */
  function getCurrentBalance() external override returns (uint256) {
    require(msg.sender == delegate || msg.sender == owner());
    uint256 balance = address(this).balance;
    return balance;
  }
  /**
   * get all token IDs In Play
   * @return {[type]} array of IDs
   */
  function getInPlay() external view returns (uint256[] memory) {
    return inPlay.getAll();
  }

  function getInPlaySize() external view returns (uint256) {
    return inPlay.size();
  }
  /**
   * get all token IDs out of Play
   * @return {[type]} array of IDs
   */
  function getOutOfPlay() external view returns (uint256[] memory) {
    return outOfPlay.getAll();
  }
  /*
   * Set Interval
   * @param {[type]} uint256 [description]
   */
  function setIntervalTime(uint256 _intervalTime) external payable returns (uint256) {
    require(msg.sender == delegate || msg.sender == owner());
    intervalTime = _intervalTime;
  }
  /*
   * isTokenInPlay - check if owner is still in player
   */
  function isTokenInPlay(uint256 _tokenId) external view returns (bool) {
    return nftRoyales[_tokenId].inPlay;
  }
  /*
   * getTokenPlacement
   */
  function getTokenPlacement(uint256 _tokenId) external view returns (uint256) {
    return nftRoyales[_tokenId].placement;
  }
  /*
   * set currentPrice
   */
  function setPrice(uint256 _price) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    price = _price;
  }
  /*
   * Toggle auto-start on or off
   */
  function autoStartOn(bool _autoStart) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    autoStart = _autoStart;
  }
  /*
   * Toggle auto-start on or off
   */
  function autoPayoutOn(bool _autoPayout) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    autoPayout = _autoPayout;
  }
  /*
   * Set Fee Rate - aggreed rate the contract takes from the artist for initial sale
   */
  function setFeeRate(uint256 _feeRate) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    feeRate = _feeRate;
  }
  /*
   * setUnitsPerTransaction
   */
  function setUnitsPerTransaction(uint256 _units) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    unitsPerTransaction = _units;
  }
  /*
   * setMaxSupply
   */
  function setMaxSupply(uint256 supply) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    maxSupply = supply;
  }
  /*
   * setdefaultTokenURI method to set the meta-data uri for the winning token to
   * be set later when game has ended
   * @param string IPFS meta-data uri
   */
  function setDefaultTokenURI(string memory _tokenUri) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    defaultTokenURI = _tokenUri;
  }
  /*
   * setPrizeTokenURI method to set the meta-data uri for the winning token to
   * be set later when game has ended
   * @param string IPFS meta-data uri
   */
  function setPrizeTokenURI(string memory _tokenUri) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    prizeTokenURI = _tokenUri;
  }
  /*
   * set artist
   */
  function setArtist(address payable _artist) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    artist = _artist;
  }
  /*
   * Delegate notifier method
   */
  function notifyGameEnded() internal {
    BattleRoyaleArena arena = BattleRoyaleArena(payable(delegate));

    arena.gameDidEnd(address(this));
  }
  /*
   * getBattleState
   * @return current state string of the game to web app
   */
  function getBattleState() external view returns (string memory) {
    if (battleState == BATTLE_STATE.STANDBY) {
      return 'STANDBY';
    }

    if (battleState == BATTLE_STATE.RUNNING) {
      return 'RUNNING';
    }

    if (battleState == BATTLE_STATE.ENDED) {
      return 'ENDED';
    }
  }

  function getBattleStateInt() external view returns (uint256) {
    return uint256(battleState);
  }
  /*
   * beginBattle
   * Method to call to begin the game battle
   */
  function beginBattle() external {
    require(msg.sender == delegate || msg.sender == owner());
    startBattle();
  }

  function startBattle() internal {
    require(bytes(prizeTokenURI).length > 0 && inPlay.size() > 1);

    battleState = BATTLE_STATE.RUNNING;
    // Set to current clock
    timestamp = block.timestamp;
  }
  /*
   * executeRandomElimination trigger elimination using Chainlink VRF
   */
  function executeRandomElimination(uint256 _randomNumber) external payable {
    require(msg.sender == delegate || msg.sender == owner());
    require(battleState == BATTLE_STATE.RUNNING);
    require(inPlay.size() > 1);

    uint256 i = _randomNumber % inPlay.size();
    uint256 tokenId = inPlay.atIndex(i);
    outOfPlay.push(tokenId);
    inPlay.remove(tokenId);
    NFTRoyale storage royale = nftRoyales[tokenId];
    royale.inPlay = false;
    royale.placement = inPlay.size() + 1;
    timestamp = block.timestamp;

    if (inPlay.size() == 1) {
      battleState = BATTLE_STATE.ENDED;
      royale = nftRoyales[tokenId];
      royale.inPlay = false;
      royale.placement = inPlay.size();
      tokenId = inPlay.atIndex(0);
      _setTokenURI(tokenId, prizeTokenURI);
      notifyGameEnded();

      if (autoPayout) {
        executeAutoPayout();
      }
    }
  }
  /*
   * calculateFee
   * Uses basis points to calculate fee
   */
  function calculateFee(uint amount) internal returns (uint) {
    require((amount / 1000) * 1000 == amount, 'amount is too small');
    return amount * feeRate / 10000;
  }
  /*
   * payout artist
   */
  function executePayout() public payable {
    require(msg.sender == delegate || msg.sender == owner());
    executeAutoPayout();
  }

  function executeAutoPayout() internal {
    uint256 balance = address(this).balance;
    if (artist != address(0)
    && (balance / 1000) * 1000 == balance
    && feeRate > 0) {
      uint256 payout = balance - calculateFee(balance);
      artist.transfer(payout);
    }

    balance = address(this).balance;
    payable(delegate).transfer(balance);
  }
}
