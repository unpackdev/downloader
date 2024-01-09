// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./console.sol";

contract BattleRoyaleNoPrize is ERC721URIStorage, Ownable {
  using SafeERC20 for IERC20;
  using Strings for uint256;

  /// @notice Event emitted when contract is deployed.
  event BattleRoyaleDeployed();

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

  /// @notice Event emitted when default token uri set.
  event DefaultTokenURISet(string defaultTokenURI);

  /// @notice Event emitted when prize token uri set.
  event PrizeTokenURISet(string prizeTokenURI);

  /// @notice Event emitted when interval time set.
  event IntervalTimeSet(uint256 intervalTime);

  /// @notice Event emitted when token price set.
  event PriceSet(uint256 price);

  /// @notice Event emitted when the units per transaction set.
  event UnitsPerTransactionSet(uint256 unitsPerTransaction);

  /// @notice Event emitted when max supply set.
  event MaxSupplySet(uint256 maxSupply);

  enum BATTLE_STATE {
    STANDBY,
    RUNNING,
    ENDED
  }

  BATTLE_STATE public battleState;

  string public baseURI;
  string public defaultTokenURI;
  string public prizeTokenURI;

  uint256 public price;
  uint256 public maxSupply;
  uint256 public totalSupply;
  uint256 public unitsPerTransaction;
  uint256 public startingTime;

  uint32[] public inPlay;

  /**
   * @dev Constructor function
   * @param _name Token name
   * @param _symbol Token symbol
   * @param _price Token price
   * @param _unitsPerTransaction Purchasable token amounts per transaction
   * @param _maxSupply Maximum number of mintable tokens
   * @param _defaultTokenURI Deafult token uri
   * @param _prizeTokenURI Prize token uri
   * @param _baseURI Base token uri
   * @param _startingTime Start time to purchase NFT
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _price,
    uint256 _unitsPerTransaction,
    uint256 _maxSupply,
    string memory _baseURI,
    string memory _defaultTokenURI,
    string memory _prizeTokenURI,
    uint256 _startingTime
  ) ERC721(_name, _symbol) {
    battleState = BATTLE_STATE.STANDBY;
    price = _price;
    unitsPerTransaction = _unitsPerTransaction;
    maxSupply = _maxSupply;
    baseURI = _baseURI;
    defaultTokenURI = _defaultTokenURI;
    prizeTokenURI = _prizeTokenURI;
    startingTime = _startingTime;

    emit BattleRoyaleDeployed();
  }

  /**
   * @dev External function to purchase tokens.
   * @param _amount Token amount to buy
   */
  function purchase(uint256 _amount) external payable {
    require(price > 0, "Token price is zero");
    require(battleState == BATTLE_STATE.STANDBY, "Not ready to purchase tokens");
    require(maxSupply > 0 && totalSupply < maxSupply, "All NFTs were sold out");
    require(block.timestamp >= startingTime, "Not time to purchase");

    if (msg.sender != owner()) {
      require(
        _amount <= maxSupply - totalSupply && _amount > 0 && _amount <= unitsPerTransaction,
        "Out range of token amount"
      );
      require(bytes(defaultTokenURI).length > 0, "Default token URI is not set");
      require(msg.value >= (price * _amount), "Not enough ETH for buying tokens");
    }

    for (uint256 i = 0; i < _amount; i++) {
      uint256 tokenId = totalSupply + i + 1;

      _safeMint(msg.sender, tokenId);

      string memory tokenURI = string(abi.encodePacked(baseURI, defaultTokenURI));

      _setTokenURI(tokenId, tokenURI);

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
    require(bytes(prizeTokenURI).length > 0 && inPlay.length > 1, "Not enough tokens to play");
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

    string memory tokenURI = string(abi.encodePacked(baseURI, prizeTokenURI));

    emit BattleEnded(address(this), _winnerTokenId, _winnerTokenId, tokenURI);
  }

  /**
   * @dev External function to set the base token URI. This function can be called only by owner.
   * @param _tokenURI New base token uri
   */
  function setBaseURI(string memory _tokenURI) external onlyOwner {
    baseURI = _tokenURI;

    emit BaseURISet(baseURI);
  }

  /**
   * @dev External function to set the default token URI. This function can be called only by owner.
   * @param _tokenURI New default token uri
   */
  function setDefaultTokenURI(string memory _tokenURI) external onlyOwner {
    defaultTokenURI = _tokenURI;

    emit DefaultTokenURISet(defaultTokenURI);
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
   * @dev External function to set max supply. This function can be called only by owner.
   * @param _maxSupply New maximum token amounts
   */
  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;

    emit MaxSupplySet(maxSupply);
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
