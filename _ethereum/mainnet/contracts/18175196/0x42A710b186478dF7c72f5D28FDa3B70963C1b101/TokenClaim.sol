// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./ITokenSale.sol";

contract TokenClaim is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  event Claim(address indexed _recipient, uint256 _claimAmount);

  address public token;
  uint256 public startAt;
  address public tokenSaleStep1;
  address public tokenSaleStep2;
  
  mapping(address => bool) public claimed;
  mapping(address => bool) public refunded;

  constructor(
    address _token,
    uint256 _startAt,
    address _tokenSaleStep1,
    address _tokenSaleStep2
  ) {
    token = _token;
    startAt = _startAt;
    tokenSaleStep1 = _tokenSaleStep1;
    tokenSaleStep2 = _tokenSaleStep2;
  }

  /********************************** View Functions **********************************/

  /// @notice Return purchased amount of account.
  function shares(address _account) public returns (uint256 _share) {
    if (refunded[_account]) return 0;
    return ITokenSale(tokenSaleStep1).shares(_account).add(ITokenSale(tokenSaleStep2).shares(_account));
  }

  /********************************** Mutated Functions **********************************/

  /// @notice Claim purchased token.
  function claim() external nonReentrant {
    // 1. check timestamp and claimed.
    require(block.timestamp > startAt, "TokenClaim: claim has not started");
    require(!claimed[msg.sender], "TokenClaim: already claimed");

    // 2. check claiming amount
    uint256 _claimAmount = shares(msg.sender);
    require(_claimAmount > 0, "TokenClaim: no share to claim");
    claimed[msg.sender] = true;

    // 3. transfer
    if (_claimAmount > 0) {
      IERC20(token).safeTransfer(msg.sender, _claimAmount);
    }

    emit Claim(msg.sender, _claimAmount);
  }

  /********************************** Restricted Functions **********************************/
  function updateStartAt(uint256 _startAt) external onlyOwner {
    startAt = _startAt;
  }

  function updateRefunded(address[] memory _accounts, bool value) external onlyOwner {
    for (uint256 i =0; i < _accounts.length; i++) {
      address _account = _accounts[i];
      refunded[_account] = value;
    }
  }

  function withdrawFund(address _recipient) external onlyOwner {
    uint256 _balance = IERC20(token).balanceOf(address(this));
    IERC20(token).safeTransfer(_recipient, _balance);
  }
}