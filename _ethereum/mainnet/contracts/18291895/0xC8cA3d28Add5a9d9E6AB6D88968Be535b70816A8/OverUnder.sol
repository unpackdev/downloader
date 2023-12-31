// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Context.sol";
import "./IERC20.sol";

contract OverUnder is Context, Ownable, VRFConsumerBaseV2 {
  using SafeERC20 for IERC20;

  uint256 private constant PERCENT_DENOMENATOR = 1000;

  uint256 public createFee;
  mapping(address => bool) public whitelist;

  VRFCoordinatorV2Interface _vrfCoordinator;
  uint64 _vrfSubId;
  bytes32 _vrfKeyHash;
  uint16 _vrfBlocks = 3;
  uint32 _vrfCallbackLimit = 300000;

  uint256 public payoutMultipleFactor = 985;

  uint8 public numberFloor = 1;
  uint8 public numberCeil = 100;

  mapping(uint256 => address) _selectInitUser;
  mapping(uint256 => address) _selectInitToken;
  mapping(uint256 => uint256) _selectInitAmount;
  mapping(uint256 => uint8) _selectInitSideSelected;
  mapping(uint256 => bool) _selectInitIsOver;
  mapping(uint256 => uint256) _selectInitPayoutMultiple;
  mapping(uint256 => uint256) _selectInitNonce;
  mapping(uint256 => bool) _selectInitSettled;
  mapping(address => uint256) public userWagerNonce;

  event SelectNumber(
    address indexed user,
    uint256 indexed nonce,
    uint8 indexed numSelected,
    bool isOver,
    uint256 payoutMultiple,
    uint256 amountWagered,
    uint256 requestId
  );
  event GetResult(
    address indexed user,
    uint256 indexed nonce,
    uint8 indexed numSelected,
    bool isWinner,
    bool isOver,
    uint256 payoutMultiple,
    uint256 amountWagered,
    uint8 numDrawn,
    uint256 amountToWin,
    uint256 requestId
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

  function selectNumber(
    uint8 _numSelected,
    bool _isOver,
    address _token,
    uint256 _amount
  ) external payable {
    require(whitelist[_token], 'TOKEN');
    _processFee(msg.value, createFee);

    require(_numSelected > numberFloor && _numSelected < numberCeil, 'FC');
    uint256 _payoutMultiple = getPayoutMultiple(_numSelected, _isOver);
    uint256 _before = IERC20(_token).balanceOf(address(this));
    uint256 _winAmount = (_amount * _payoutMultiple) / PERCENT_DENOMENATOR;
    require(_before >= _winAmount, 'PAYOUT');

    IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
    uint256 _requestId = _vrfCoordinator.requestRandomWords(
      _vrfKeyHash,
      _vrfSubId,
      _vrfBlocks,
      _vrfCallbackLimit,
      uint16(1)
    );

    _selectInitUser[_requestId] = _msgSender();
    _selectInitToken[_requestId] = _token;
    _selectInitAmount[_requestId] = _amount;
    _selectInitSideSelected[_requestId] = _numSelected;
    _selectInitIsOver[_requestId] = _isOver;
    _selectInitPayoutMultiple[_requestId] = _payoutMultiple;
    _selectInitNonce[_requestId] = userWagerNonce[_msgSender()];
    userWagerNonce[_msgSender()]++;
    emit SelectNumber(
      _msgSender(),
      _selectInitNonce[_requestId],
      _numSelected,
      _isOver,
      _selectInitPayoutMultiple[_requestId],
      _amount,
      _requestId
    );
  }

  function getPayoutMultiple(
    uint8 _numSelected,
    bool _isOver
  ) public view returns (uint256) {
    require(_numSelected > numberFloor && _numSelected < numberCeil, 'BOUNDS');
    uint256 odds;
    if (_isOver) {
      odds = (numberCeil * payoutMultipleFactor) / (numberCeil - _numSelected);
    } else {
      odds = (numberCeil * payoutMultipleFactor) / (_numSelected - numberFloor);
    }
    return odds - 1000;
  }

  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomWords
  ) internal override {
    address _user = _selectInitUser[_requestId];
    require(_user != address(0), 'RECORD');
    require(!_selectInitSettled[_requestId], 'SETTLED');
    _selectInitSettled[_requestId] = true;

    uint256 _winAmount = (_selectInitAmount[_requestId] *
      _selectInitPayoutMultiple[_requestId]) / PERCENT_DENOMENATOR;
    uint8 _numberDrawn = uint8(
      _randomWords[0] % (numberCeil - numberFloor + 1)
    ) + numberFloor;
    bool _userWon = _selectInitIsOver[_requestId]
      ? _numberDrawn > _selectInitSideSelected[_requestId]
      : _numberDrawn < _selectInitSideSelected[_requestId];

    if (_userWon) {
      uint256 _winTotal = _selectInitAmount[_requestId] + _winAmount;
      IERC20(_selectInitToken[_requestId]).safeTransfer(_user, _winTotal);
    } else if (_numberDrawn == _selectInitSideSelected[_requestId]) {
      // draw
      IERC20(_selectInitToken[_requestId]).safeTransfer(
        _user,
        _selectInitAmount[_requestId]
      );
    }

    emit GetResult(
      _user,
      _selectInitNonce[_requestId],
      _selectInitSideSelected[_requestId],
      _userWon,
      _selectInitIsOver[_requestId],
      _selectInitPayoutMultiple[_requestId],
      _selectInitAmount[_requestId],
      _numberDrawn,
      _winAmount,
      _requestId
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

  function setPayoutMultipleFactor(uint256 _factor) external onlyOwner {
    payoutMultipleFactor = _factor;
  }

  function setFloorAndCeil(uint8 _floor, uint8 _ceil) external onlyOwner {
    require(_ceil > _floor && _ceil - _floor >= 2, 'TWOUNITS');
    numberFloor = _floor;
    numberCeil = _ceil;
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
