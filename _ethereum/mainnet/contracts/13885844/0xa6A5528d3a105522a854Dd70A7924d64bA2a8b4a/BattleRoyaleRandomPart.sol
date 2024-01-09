// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721URIStorage.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract BattleRoyaleRandomPart is ERC721URIStorage, Ownable {
  using SafeERC20 for IERC20;

  /// @notice Event emitted when contract is deployed.
  event BattleRoyaleRandomPartDeployed();

  /// @notice Event emitted when owner withdrew the ETH.
  event EthWithdrew(address receiver);

  /// @notice Event emitted when owner withdrew the ERC20 token.
  event ERC20TokenWithdrew(address receiver);

  /// @notice Event emitted when user purchased the tokens.
  event Purchased(address user, uint256 amount, uint256 totalSupply);

  /// @notice Event emitted when owner has set starting time.
  event StartingTimeSet(uint256 time);

  /// @notice Event emitted when battle has started.
  event BattleStarted(address battleAddress, uint32[] inPlay);

  /// @notice Event emitted when battle has ended.
  event BattleEnded(
    address battleAddress,
    uint256 tokenId,
    uint256 winnerTokenId,
    string prizeTokenURI
  );

  /// @notice Event emitted when base token uri set.
  event BaseURISet(string baseURI);

  /// @notice Event emitted when token URIs has added.
  event TokenURIAdded(string tokenURI, uint256 count);

  /// @notice Event emitted when token URI count has updated.
  event TokenURICountUpdated(string tokenURI, uint256 count);

  /// @notice Event emitted when token URI has removed.
  event TokenURIRemoved(uint256 index, string[] defaultTokenURI, uint256 totalDefaultNFTTypeCount);

  /// @notice Event emitted when prize token uri set.
  event PrizeTokenURISet(string prizeTokenURI);

  /// @notice Event emitted when interval time set.
  event IntervalTimeSet(uint256 intervalTime);

  /// @notice Event emitted when token price set.
  event PriceSet(uint256 price);

  /// @notice Event emitted when the units per transaction set.
  event UnitsPerTransactionSet(uint256 defaultTokenURI);

  /// @notice Event emitted when max supply set.
  event MaxSupplySet(uint256 maxSupply);

  enum BATTLE_STATE {
    STANDBY,
    RUNNING,
    ENDED
  }

  BATTLE_STATE public battleState;

  string public prizeTokenURI;
  string[] public defaultTokenURI;
  string public baseURI;
  uint256 public price;
  uint256 public maxSupply;
  uint256 public totalSupply;
  uint256 public unitsPerTransaction;
  uint256 public startingTime;
  uint256 public defaultNFTTypeCount;
  uint256 public totalDefaultNFTTypeCount;

  uint32[] public inPlay;

  mapping(string => uint256) public tokenURICount;

  /**
   * @dev Constructor function
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _price Token price
   * @param _unitsPerTransaction Purchasable token amounts per transaction
   * @param _prizeTokenURI Prize token uri
   * @param _baseURI Base token uri
   * @param _startingTime Start time to purchase NFT
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _price,
    uint256 _unitsPerTransaction,
    string memory _prizeTokenURI,
    string memory _baseURI,
    uint256 _startingTime
  ) ERC721(_name, _symbol) {
    battleState = BATTLE_STATE.STANDBY;
    price = _price;
    unitsPerTransaction = _unitsPerTransaction;
    prizeTokenURI = _prizeTokenURI;
    baseURI = _baseURI;
    startingTime = _startingTime;
    emit BattleRoyaleRandomPartDeployed();
  }

  /**
   * @dev External function to purchase tokens.
   * @param _amount Token amount to buy
   */
  function purchase(uint256 _amount) external payable {
    require(battleState == BATTLE_STATE.STANDBY, "Not ready to purchase tokens");
    require(maxSupply > 0 && totalSupply < maxSupply, "All NFTs were sold out");

    require(block.timestamp >= startingTime, "Not time to purchase");

    if (msg.sender != owner()) {
      require(
        _amount <= maxSupply - totalSupply && _amount > 0 && _amount <= unitsPerTransaction,
        "Out range of token amount"
      );
      require(msg.value >= (price * _amount), "Not enough ETH for buying tokens");
    }

    for (uint256 i = 0; i < _amount; i++) {
      uint256 tokenId = totalSupply + i + 1;

      _safeMint(msg.sender, tokenId);

      uint256 index = uint256(
        keccak256(abi.encode(i, _amount, block.timestamp, msg.sender, tokenId))
      ) % defaultNFTTypeCount;

      _setTokenURI(tokenId, string(abi.encodePacked(baseURI, defaultTokenURI[index])));

      tokenURICount[defaultTokenURI[index]]--;

      if (tokenURICount[defaultTokenURI[index]] == 0) {
        string memory defaultTokenURICID = defaultTokenURI[index];
        defaultTokenURI[index] = defaultTokenURI[defaultNFTTypeCount - 1];
        defaultTokenURI[defaultNFTTypeCount - 1] = defaultTokenURICID;
        defaultNFTTypeCount--;
      }

      inPlay.push(uint32(tokenId));
    }

    totalSupply += _amount;

    emit Purchased(msg.sender, _amount, totalSupply);
  }

  /**
   * @dev External function to set starting time. This function can be called only by owner.
   */
  function setStartingTime(uint256 _newTime) external onlyOwner {
    startingTime = _newTime;

    emit StartingTimeSet(_newTime);
  }

  /**
   * @dev External function to start the battle. This function can be called only by owner.
   */
  function startBattle() external onlyOwner {
    battleState = BATTLE_STATE.RUNNING;

    emit BattleStarted(address(this), inPlay);
  }

  /**
   * @dev External function to end the battle. This function can be called only by owner.
   * @param _winnerTokenId Winner token Id in battle
   */
  function endBattle(uint256 _winnerTokenId) external onlyOwner {
    require(battleState == BATTLE_STATE.RUNNING, "Battle is not started");
    battleState = BATTLE_STATE.ENDED;

    uint256 tokenId = totalSupply + 1;

    _safeMint(ownerOf(_winnerTokenId), tokenId);

    _setTokenURI(tokenId, string(abi.encodePacked(baseURI, prizeTokenURI)));

    emit BattleEnded(
      address(this),
      tokenId,
      _winnerTokenId,
      string(abi.encodePacked(baseURI, prizeTokenURI))
    );
  }

  /**
   * @dev External function to set the base token URI. This function can be called only by owner.
   * @param _newBaseURI New base token uri
   */
  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;

    emit BaseURISet(baseURI);
  }

  /**
   * @dev External function to add token URI. This function can be called only by owner.
   * @param _tokenURI New token uri
   * @param _count Token uri count
   */
  function addTokenURI(string memory _tokenURI, uint256 _count) external onlyOwner {
    defaultTokenURI.push(_tokenURI);
    tokenURICount[_tokenURI] = _count;
    maxSupply += _count;
    defaultNFTTypeCount++;
    totalDefaultNFTTypeCount++;
    emit TokenURIAdded(_tokenURI, _count);
  }

  /**
   * @dev External function to change the token uri. This function can be called only by owner.
   * @param _tokenURI Token uri
   * @param _count Token uri count
   */
  function updateTokenURICount(string memory _tokenURI, uint256 _count) external onlyOwner {
    maxSupply = maxSupply - tokenURICount[_tokenURI] + _count;
    tokenURICount[_tokenURI] = _count;

    emit TokenURICountUpdated(_tokenURI, _count);
  }

  /**
   * @dev External function to remove the token uri. This function can be called only by owner.
   * @param _index Index of token uri
   */
  function removeTokenURI(uint256 _index) external onlyOwner {
    string memory tokenURI = defaultTokenURI[_index];
    maxSupply -= tokenURICount[tokenURI];
    delete tokenURICount[tokenURI];
    defaultTokenURI[_index] = defaultTokenURI[defaultTokenURI.length - 1];
    defaultTokenURI.pop();
    defaultNFTTypeCount--;
    totalDefaultNFTTypeCount--;
    emit TokenURIRemoved(_index, defaultTokenURI, totalDefaultNFTTypeCount);
  }

  /**
   * @dev External function to set the prize token URI. This function can be called only by owner.
   * @param _tokenURI New prize token uri
   */
  function setPrizeTokenURI(string memory _tokenURI) external onlyOwner {
    prizeTokenURI = _tokenURI;

    emit PrizeTokenURISet(prizeTokenURI);
  }

  /**
   * @dev External function to set the token price. This function can be called only by owner.
   * @param _price New token price
   */
  function setPrice(uint256 _price) external onlyOwner {
    price = _price;

    emit PriceSet(price);
  }

  /**
   * @dev External function to set the limit of buyable token amounts. This function can be called only by owner.
   * @param _unitsPerTransaction New purchasable token amounts per transaction
   */
  function setUnitsPerTransaction(uint256 _unitsPerTransaction) external onlyOwner {
    unitsPerTransaction = _unitsPerTransaction;

    emit UnitsPerTransactionSet(unitsPerTransaction);
  }

  /**
   * Fallback function to receive ETH
   */
  receive() external payable {}

  /**
   * @dev External function to withdraw ETH in contract. This function can be called only by owner.
   * @param _amount ETH amount
   */
  function withdrawETH(uint256 _amount) external onlyOwner {
    uint256 balance = address(this).balance;
    require(_amount <= balance, "Out of balance");

    payable(msg.sender).transfer(_amount);

    emit EthWithdrew(msg.sender);
  }

  /**
   * @dev External function to withdraw ERC-20 tokens in contract. This function can be called only by owner.
   * @param _tokenAddr Address of ERC-20 token
   * @param _amount ERC-20 token amount
   */
  function withdrawERC20Token(address _tokenAddr, uint256 _amount) external onlyOwner {
    IERC20 token = IERC20(_tokenAddr);

    uint256 balance = token.balanceOf(address(this));
    require(_amount <= balance, "Out of balance");

    token.safeTransfer(msg.sender, _amount);

    emit ERC20TokenWithdrew(msg.sender);
  }
}
