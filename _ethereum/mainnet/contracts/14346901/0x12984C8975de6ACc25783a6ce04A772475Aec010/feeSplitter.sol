pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./IERC20.sol";

contract feeSplitter is AccessControl {
  using SafeMath for uint256;
  //20 % and 80% 
  uint32 public feeDivisor1 = 2000;
  uint32 public feeDivisor2 = 8000;
  address public addressFee1 = 0x56c372522C5f82BB9e4934541F0cC8EfB61f543d;
  address public addressFee2 = 0xb89C16f529C59B42F7B668ACf6deE638166072e0;
  IERC20 public token;

  constructor(IERC20 _token) {
    token = _token;

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 amount = token.balanceOf(address(this));
    uint256 feeAmount1 = amount.mul(feeDivisor1).div(1e4);
    uint256 feeAmount2 = amount.sub(feeAmount1);

    token.transfer(addressFee1, feeAmount1);
    token.transfer(addressFee2, feeAmount2);
  }

  function setAdmin(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(DEFAULT_ADMIN_ROLE, _address);
  }

  function removeAdmin(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(DEFAULT_ADMIN_ROLE, _address);
  }
}
