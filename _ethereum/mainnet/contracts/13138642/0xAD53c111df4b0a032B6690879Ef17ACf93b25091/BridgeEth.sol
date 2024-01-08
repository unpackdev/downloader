// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWWMMMMMMMMMMMMMMMMMMWWNNWWMMMMMMMMMMMMMMMMMMMWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKxood0WMMMMMMMMMMMMMMMMNOdoodOXWMMMMMMMMMMMMMMMMNK0K00KWMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo;;;;oKWMMMMMMMMMMMMMMW0l;;;;ckNMMMMMMMMMMMMMMMMWK0OkxONMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKko;;;;l0WMMMMMMMMMMMMMMMNkolclxXWMMMMMMMMMMMMMMMMMWWWWWWWMMM
MMMWNNWMMMMWNNXNNWMMMMMWWNXXNNWMMMMMMMMMMMWNNXKKXXNWWMMMMMWKko;;;;l0WWWXXKKXNWWMMMMMMWX00KNMMMMMMMWWNXXKXXNWWMMMMMMMMMMM
MNKxood0NXOdolllodOXWN0xollllldkKWMMMMMWXOxolcccccldx0NWMMWKko;;;;lO0kolccccldkKWMMMW0dlloONMMMWN0kdlcccccldkKNMMMMMMMMM
W0l;;;;col:;;;;;;;:lxo:;;;;;;;;:lONMMW0dc:;;;;;;;;;;;:lkXWWKko;;;;clc:;;;;;;;;:cxKWMXd;;;;l0WMN0o:;;;;::;;;;;cd0WMMMMMMM
WOc;;;;;;clool:;;;;;;;:lool:;;;;;l0WNkc;;;;:ldxxxoc:;;;:o0NKko;;;;;;:ldkkxoc;;;;:o0WKo;;;;l0WXxc;;;:lxkOkdl:;;;lONMMMMMM
WOl;;;;:o0NNNKkc;;;;;lOXNNXOl;;;;:xXk:;;;:oONWWWWNKxc;;;;l0KOo;;;;;lkXWWMWN0o:;;;;dKKo;;;;l0Xkc;;;cxKWWWWN0o:;;;l0WMMMMM
W0l;;;;cONMMMWXd;;;;:kNMMMMNx:;;;:xOl;;;;l0WMMMMMMWXxc;;;:x0Oo;;;;cONMMMMMMWKo;;;;cOKo;;;;l00o;;;;cdkkkkkkko:;;;cxNMMMMM
W0l;;;;l0WMMMMNx:;;;ckWMMMMNkc;;;:xOl;;;:dXMMMMMMMMWOl;;;;d0Oo;;;;l0WMMMMMMMXd:;;;ckKo;;;;l00l;;;;;:::::::::;;;:cONMMMMM
W0l;;;;l0WMMMMNx:;;;ckWMMMMNkc;;;:x0o;;;;l0WMMMMMMWXx:;;;:x0Oo;;;;ckNMMMMMMWKo;;;;cOKo;;;;l00o:;;;coxkkkkkkkkkkOKNWMMMMM
W0l;;;;l0WMMMMNx:;;;ckWMMMMNkc;;;:xKkc;;;;lkXNWWWNKxc;;;;oKKko;;;;;cxKNWWNXOo:;;;:dXKo;;;;l0Xkc;;;:d0NWWWWWXKOOXWMMMMMMM
WOl;;;;l0WMMMMNx:;;;ckWMMMMNkc;;;:xXNkl:;;;:codddoc:;;;:dKWKOo;;;;;;:codddl:;;;;:oKWXo;;;;l0NXkc;;;;cdxkkxdlc;:oKMMMMMMM
W0l;;;;l0WMMMMNx:;;;cOWMMMMNkc;;;:xNWWKxl:;;;;;;;;;;;coONWWX0d;;;;clc:;;;;;;;;:lkXWWXd:;;;l0WMW0dc:;;;;;;;;;;:cxXMMMMMMM
MN0dlloONMMMMMWKxllokXWMMMMWXkollxXWMMMWX0xdollllloxkKNWMMMWNKxood0XKOdolllodx0XWMMMWKxold0NMMMMWXOxolllllloxOXWMMMMMMMM
MMMWNXNWMMMMMMMMWNXNWMMMMMMMMWNNNWMMMMMMMMWWNNXXNNWWMMMMMMMMMMWWWWMMMWWNNNNNWWMMMMMMMMWWNWMMMMMMMMMWWNNXXNNWWMMMMMMMMMMM
*/

import "./SafeMath.sol";
import "./IERC20Burnable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract WMBXBridge is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  constructor(address _token, address payable _feeAddress, uint256 _claimFeeRate, uint256 _burnFeeRate) {
    TOKEN = IERC20(_token);
    feeAddress = _feeAddress;
    claimFeeRate = _claimFeeRate;
    burnFeeRate = _burnFeeRate;
    isFrozen = false;
  }

  IERC20 private TOKEN;

  address payable private feeAddress;
  uint256 private claimFeeRate;
  uint256 private burnFeeRate;
  bool private isFrozen;

  /* Defines a mint operation */
  struct MintOperation
  {
    address user;
    uint256 amount;
    bool isReceived;
    bool isProcessed;
  }

  mapping (string => MintOperation) private _mints;  // History of mint claims

  struct MintPending
  {
    string memo;
    bool isPending;
  }

  mapping (address => MintPending) private _pending; // Pending mint owners

  struct BurnOperation
  {
    uint256 amount;
    bool isProcessed;
  }

  mapping (string => BurnOperation) private _burns;  // History of burn requests

  mapping (address => bool) private _validators;

  event BridgeAction(address indexed user, string action, uint256 amount, uint256 fee, string memo);
  // event BridgeBurn(address indexed user, uint256 amount, uint256 fee, string memo);

  function getPending(address _user) external view returns(string memory) {
    require(msg.sender == _user || _validators[msg.sender] || msg.sender == owner(), "Not authorized.");
    if(_pending[_user].isPending){
      return _pending[_user].memo;
    } else {
      return "";
    }
  }

  function claimStatus(string memory _memo) external view returns(address user, uint256 amount, bool received, bool processed) {
    require (_mints[_memo].isReceived, "Memo not found.");
    require(msg.sender == _mints[_memo].user || _validators[msg.sender] || msg.sender == owner(), "Not authorized.");
    user = _mints[_memo].user;
    amount = _mints[_memo].amount;
    received = _mints[_memo].isReceived;
    processed = _mints[_memo].isProcessed;
  }

  function isValidator(address _user) external view returns (bool) {
    return _validators[_user];
  }

  function addValidator(address _user) external onlyOwner nonReentrant {
    require (!_validators[_user], "Address already validator.");
    _validators[_user] = true;
  }

  function removeValidator(address _user) external onlyOwner nonReentrant {
    require (_validators[_user], "Address not found.");
    _validators[_user] = false;
  }

  function getFeeAddress() external view returns (address) {
    return feeAddress;
  }

  function setFeeAddress(address payable _feeAddress) external onlyOwner nonReentrant {
    feeAddress = _feeAddress;
  }

  function getClaimFeeRate() external view returns (uint256) {
    return claimFeeRate;
  }

  function getBurnFeeRate() external view returns (uint256) {
    return burnFeeRate;
  }

  function setClaimFeeRate(uint256 _claimFeeRate) external onlyOwner nonReentrant {
    claimFeeRate = _claimFeeRate;
  }

  function setBurnFeeRate(uint256 _burnFeeRate) external onlyOwner nonReentrant {
    burnFeeRate = _burnFeeRate;
  }

  function getFrozen() external view returns (bool) {
    return isFrozen;
  }

  function setFrozen(bool _isFrozen) external onlyOwner nonReentrant {
    isFrozen = _isFrozen;
  }

  function burnTokens(string memory _memo, uint256 _amount) external payable nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(msg.value >= burnFeeRate, "Fee not met");
    require(TOKEN.allowance(msg.sender, address(this)) >= _amount, "No allowance");
    TOKEN.burnFrom(msg.sender, _amount);
    feeAddress.transfer(msg.value);
    emit BridgeAction(msg.sender, 'BURN', _amount, msg.value, _memo);
  }

  function validateMint(address _user, string memory _memo, uint256 _amount) external nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(_validators[msg.sender], "Not authorized");
    require(_amount > 0, "Amount must be greater than zero.");
    require(!_mints[_memo].isReceived, "Mint already logged.");
    require(!_pending[_user].isPending, "Owner already has mint pending.");
    _mints[_memo] = MintOperation(_user, _amount, true, false);
    _pending[_user] = MintPending(_memo, true);
  }

  function claimTokens(string memory _memo) external payable nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(_mints[_memo].isReceived, "Memo not found");
    require(_mints[_memo].user == msg.sender, "Not owner");
    require(!_mints[_memo].isProcessed, "Memo already processed");
    require(msg.value >= claimFeeRate, "Fee not met");
    TOKEN.mint(msg.sender, _mints[_memo].amount);
    feeAddress.transfer(msg.value);
    _mints[_memo].isProcessed = true;
    _pending[_mints[_memo].user].isPending = false;
    emit BridgeAction(msg.sender, "CLAIM", _mints[_memo].amount, msg.value, _memo);
  }

}
