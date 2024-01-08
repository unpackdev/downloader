// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./IERC20Burnable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract WMBXBridge is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  constructor(address _token, address payable _feeAddress, uint256 _claimFeeRate, uint256 _burnFeeRate) {
    TOKEN = IERC20Burnable(_token);
    feeAddress = _feeAddress;
    claimFeeRate = _claimFeeRate;
    burnFeeRate = _burnFeeRate;
    isFrozen = false;
  }

  IERC20Burnable private TOKEN;

  address payable private feeAddress;
  uint256 private claimFeeRate;
  uint256 private burnFeeRate;
  bool private isFrozen;

  event BridgeBurn(address indexed user, uint256 amount, uint256 fee, string memo);
  event BridgeClaim(address indexed user, uint256 fee, string memo);

  function getFeeAddress() public view returns (address) {
    return feeAddress;
  }

  function setFeeAddress(address payable _feeAddress) public onlyOwner nonReentrant {
    feeAddress = _feeAddress;
  }

  function getClaimFeeRate() public view returns (uint256) {
    return claimFeeRate;
  }

  function getBurnFeeRate() public view returns (uint256) {
    return burnFeeRate;
  }

  function setClaimFeeRate(uint256 _claimFeeRate) public onlyOwner nonReentrant {
    claimFeeRate = _claimFeeRate;
  }

  function setBurnFeeRate(uint256 _burnFeeRate) public onlyOwner nonReentrant {
    burnFeeRate = _burnFeeRate;
  }

  function getFrozen() public view returns (bool) {
    return isFrozen;
  }

  function setFrozen(bool _isFrozen) public onlyOwner nonReentrant {
    isFrozen = _isFrozen;
  }

  function burnTokens(string memory _memo, uint256 _amount) public payable nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(msg.value >= burnFeeRate, "Fee not met");
    require(TOKEN.allowance(msg.sender, address(this)) >= _amount, "No allowance");
    TOKEN.burnFrom(msg.sender, _amount);
    feeAddress.transfer(msg.value);
    emit BridgeBurn(msg.sender, _amount, msg.value, _memo);
  }

  function claimTokens(string memory _memo) public payable nonReentrant {
    require(!isFrozen, "Contract is frozen");
    require(msg.value >= claimFeeRate, "Fee not met");
    feeAddress.transfer(msg.value);
    emit BridgeClaim(msg.sender, msg.value, _memo);
  }

}
