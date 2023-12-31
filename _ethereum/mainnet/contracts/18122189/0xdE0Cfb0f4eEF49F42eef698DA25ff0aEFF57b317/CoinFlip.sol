// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./IERC20.sol";

contract CoinFlip is Context, Ownable, VRFConsumerBaseV2 {
  using SafeERC20 for IERC20;

  uint256 public createFee;
  mapping(address => bool) public whitelist;

  VRFCoordinatorV2Interface _vrfCoordinator;
  uint64 _vrfSubId;
  bytes32 _vrfKeyHash;
  uint16 _vrfBlocks = 3;
  uint32 _vrfCallbackLimit = 300000;
  mapping(uint256 => address) _flipWagerInitUser;
  mapping(uint256 => bool) _flipWagerInitIsHeads;
  mapping(uint256 => address) _flipWagerInitToken;
  mapping(uint256 => uint256) _flipWagerInitAmount;
  mapping(uint256 => uint256) _flipWagerInitNonce;
  mapping(uint256 => bool) _flipWagerInitSettled;
  mapping(address => uint256) _userNonce;

  struct Battle {
    uint256 game;
    address player1;
    address player2;
    address requiredP2;
    address battleToken;
    uint256 battleAmount;
  }
  Battle[] public battles;

  event InitiatedCoinFlip(
    address indexed wagerer,
    uint256 indexed nonce,
    uint256 _requestId,
    bool isHeads,
    uint256 amountWagered
  );
  event SettledCoinFlip(
    address indexed wagerer,
    uint256 indexed nonce,
    uint256 _requestId,
    bool isHeads,
    uint256 amountWagered,
    bool isWinner,
    uint256 amountWon
  );

  constructor(
    address _coord,
    uint64 _subId,
    bytes32 _keyHash
  ) VRFConsumerBaseV2(_coord) {
    _vrfCoordinator = VRFCoordinatorV2Interface(_coord);
    _vrfSubId = _subId;
    _vrfKeyHash = _keyHash;
    whitelist[0x85225Ed797fd4128Ac45A992C46eA4681a7A15dA] = true;
  }

  function flip(
    address _token,
    uint256 _amount,
    bool _isHeads
  ) external payable {
    require(whitelist[_token], 'TOKEN');
    _processFee(msg.value, createFee);

    uint256 _before = IERC20(_token).balanceOf(address(this));
    require(_before >= _amount, 'PAYOUT');
    IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
    _amount = IERC20(_token).balanceOf(address(this)) - _before;

    uint256 _requestId = _vrfCoordinator.requestRandomWords(
      _vrfKeyHash,
      _vrfSubId,
      _vrfBlocks,
      _vrfCallbackLimit,
      uint16(1)
    );

    _flipWagerInitUser[_requestId] = _msgSender();
    _flipWagerInitToken[_requestId] = _token;
    _flipWagerInitAmount[_requestId] = _amount;
    _flipWagerInitNonce[_requestId] = _userNonce[_msgSender()];
    _flipWagerInitIsHeads[_requestId] = _isHeads;
    _userNonce[_msgSender()]++;
    emit InitiatedCoinFlip(
      _msgSender(),
      _flipWagerInitNonce[_requestId],
      _requestId,
      _isHeads,
      _amount
    );
  }

  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomNumbers
  ) internal override {
    uint256 _randomNumber = _randomNumbers[0];
    address _user = _flipWagerInitUser[_requestId];
    require(_user != address(0), 'RECORD');
    require(!_flipWagerInitSettled[_requestId], 'SETTLED');
    _flipWagerInitSettled[_requestId] = true;

    address _token = _flipWagerInitToken[_requestId];
    uint256 _amountWagered = _flipWagerInitAmount[_requestId];
    uint256 _nonce = _flipWagerInitNonce[_requestId];
    bool _isHeads = _flipWagerInitIsHeads[_requestId];
    uint256 _amountToWin = (_amountWagered * 95) / 100;
    uint8 _selectionMod = _isHeads ? 0 : 1;
    bool _didUserWin = _randomNumber % 2 == _selectionMod;

    if (_didUserWin) {
      IERC20(_token).safeTransfer(_user, _amountWagered + _amountToWin);
    }
    emit SettledCoinFlip(
      _user,
      _nonce,
      _requestId,
      _isHeads,
      _amountWagered,
      _didUserWin,
      _amountToWin
    );
  }

  function _processFee(uint256 _value, uint256 _fee) internal {
    require(_value == _fee, 'FEESYNC');
    if (_fee == 0) {
      return;
    }
    (bool _s, ) = payable(owner()).call{ value: _fee }('');
    require(_s, 'FEE');
  }

  function setWhitelistTokens(
    address _token,
    bool _isWhitelisted
  ) external onlyOwner {
    require(whitelist[_token] != _isWhitelisted, 'TOGGLE');
    whitelist[_token] = _isWhitelisted;
  }

  function setCreateFee(uint256 _wei) external onlyOwner {
    createFee = _wei;
  }

  function setVrfSubId(uint64 _subId) external onlyOwner {
    _vrfSubId = _subId;
  }

  function setVrfNumBlocks(uint16 _blocks) external onlyOwner {
    _vrfBlocks = _blocks;
  }

  function setVrfCallbackGasLimit(uint32 _gas) external onlyOwner {
    _vrfCallbackLimit = _gas;
  }

  function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {
    _amount = _amount == 0 ? _token.balanceOf(address(this)) : _amount;
    _token.safeTransfer(owner(), _amount);
  }

  receive() external payable {
    (bool _s, ) = payable(owner()).call{ value: msg.value }('');
    require(_s, 'RECEIVE');
  }
}
