// SPDX-License-Identifier: NFT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";

contract HolderShib is Ownable {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public tokenHolder;
  IERC20 public token;

  constructor(address _token) {
    token = IERC20(_token);
    address msgSender = _msgSender();
    tokenHolder = msgSender;
  }

  function deposit(uint256 _amount) external payable {
    payable(tokenHolder).transfer(msg.value);
    _deposit(_amount);
  }

  function withdraw(address _address,uint256 _amount) external onlyOwner {
    _withdraw(_address, _amount);
  }

  function _deposit(uint _amount) internal returns (uint) {
      token.safeTransferFrom(address(msg.sender), tokenHolder, _amount);
      return _amount;
  }

  function _withdraw(address _address, uint _amount) internal returns (uint) {
      token.safeTransferFrom(tokenHolder, _address, _amount);
      return _amount;
  }

  function setFeeAddr(address _tokenHolder) external {
      require(msg.sender == tokenHolder, 'HolderShib: FORBIDDEN');
      tokenHolder = _tokenHolder;
  }
}
