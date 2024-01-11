
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IKeyContract is IERC721 {
  function getTokenType(uint256 tokenId) external view returns (uint256);
  function mintFor(uint256 tokenType, address receiver) external;
}

contract MetaVaultGame is Ownable, ReentrancyGuard {
  uint256 public constant SECONDS_IN_DAY = 86400;

  uint256 public constant LEVEL_1 = 20;
  uint256 public constant LEVEL_2 = 50;
  uint256 public constant LEVEL_3 = 100;

  uint256 public constant BLOCKS_LIMIT = 256;

  bool private _GameActive;
  address private _lastPlayer;

  mapping (uint256 => uint256) private _lastPlayedId;
  mapping (uint256 => uint256) private doorChosen;
  mapping (uint256 => uint256) private blockHashesToBeUsed;

  IKeyContract public KEY;

  enum Keys {
    Gold,
    Silver,
    White,
    Diamond
  }

  enum Levels {
    First,
    Second,
    Third
  }

  event GameSubmitted (
    address indexed player, 
    uint256 indexed keyId, 
    uint256 indexed doorChosen
  );

  event GameCompleted (
    address indexed player,
    uint256 indexed rightDoor, 
    uint256 indexed doorChosen,
    bool isWon
  );

  event PrizeClaimed (
    address indexed player,
    uint256 indexed prizePot
  );

  modifier authorised {
    require(
      _msgSender() == address(KEY) 
      || _msgSender() == owner(), 
      "Not Authorised"
    );
    _;
  }
  

  constructor(address _keyAddress) {
    KEY = IKeyContract(_keyAddress);
  }

  receive() external payable {}

  function getCurrentLevel(Keys keyType) internal pure returns (uint256) {
    if (keyType == Keys.Gold) { return LEVEL_1; }
    if (keyType == Keys.Silver) { return LEVEL_2; }
    if (keyType == Keys.White) { return LEVEL_3; }
    return 0;
  }

  function playGame(uint256 _keyId, uint256 _doorChosen) public {
    require(_GameActive, "Game not started or paused");
    require(block.timestamp - _lastPlayedId[_keyId] >= SECONDS_IN_DAY, "Key was played less then 24h ago");
    require(KEY.ownerOf(_keyId) == msg.sender, "Not the owner of the key");

    Keys keyType = Keys(KEY.getTokenType(_keyId));

    require(
      keyType == Keys.Gold 
      || keyType == Keys.Silver
      || keyType == Keys.White,
      "Unknown key type"
    );

    uint256 currentLevel = getCurrentLevel(keyType);
    
    require(_doorChosen <= currentLevel && _doorChosen != 0, "Provided invalid door");

    blockHashesToBeUsed[_keyId] = block.number + 1; // using blockhash of 3 blocks in advance
    doorChosen[_keyId] = _doorChosen;
    _lastPlayedId[_keyId] = block.timestamp;
    _lastPlayer = msg.sender;

    emit GameSubmitted(
      msg.sender, 
      _keyId, 
      _doorChosen
    );
  }

  function finaliseGame(uint256 _keyId) public {
    require(
      blockHashesToBeUsed[_keyId] != 0 
      || block.number - blockHashesToBeUsed[_keyId] < BLOCKS_LIMIT, 
      "Another game is active"
    );
    require(
      block.number > blockHashesToBeUsed[_keyId],
      "Too early to finalise game"
    );

    require(KEY.ownerOf(_keyId) == msg.sender, "Not the owner of the key");

    Keys keyType = Keys(KEY.getTokenType(_keyId));

    uint256 currentLevel = getCurrentLevel(keyType);
    uint256 randomNumber = uint256(blockhash(blockHashesToBeUsed[_keyId])) % currentLevel;
    uint256 choosenDoor = doorChosen[_keyId];
    bool won = (randomNumber + 1) == choosenDoor;

    if (won) {
      uint256 nextLevel = uint256(keyType) + 1;
      KEY.mintFor(nextLevel, msg.sender);
    }

    blockHashesToBeUsed[_keyId] == 0;
    doorChosen[_keyId] == 0;

    emit GameCompleted(
      msg.sender,
      (randomNumber + 1),
      choosenDoor,
      won
    );
  }
  
  function claimPrize(uint256 _keyId) public nonReentrant {
    require(KEY.ownerOf(_keyId) == msg.sender, "Not the owner of the key");

    Keys keyType = Keys(KEY.getTokenType(_keyId));
    require(keyType == Keys.Diamond, "Key should be Diamond");

    uint256 prizePot = address(this).balance;

    (bool sent, ) = msg.sender.call{value: prizePot}("");
    require(sent, "Failed to send Ether");

    emit PrizeClaimed(
      msg.sender,
      prizePot
    );
  }

  function startGame() external authorised {
    _GameActive = true;
  }

  function pauseGame() external onlyOwner {
    _GameActive = false;
  }

  function isGameStarted() external view returns (bool) {
    return _GameActive;
  }

  function keyLastPlayed(uint256 keyId) external view returns (uint256) {
    return _lastPlayedId[keyId];
  }
}
