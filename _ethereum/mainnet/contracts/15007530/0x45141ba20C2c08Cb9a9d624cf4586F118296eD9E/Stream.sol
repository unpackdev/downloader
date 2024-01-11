// contracts/Stream.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeERC20.sol";

contract Stream {
  using SafeERC20 for IERC20;

  struct Member {
    address account;
    uint32 value;
    uint32 total;
  }

  struct TokenInfo {
    address token_address;
    uint256 totalReleased;
    mapping(address => uint256) totalReleasedToAccount;
  }
  
  mapping(address => TokenInfo) private _tokenInfo;
  Member[] private _members;

  constructor() {
    _members.push(Member({
      account: address(0x946F6A5B0854D2b5E770E5b9e7607dB5f4FA9fF0),
      value: 1,
      total: 12
    }));
    _members.push(Member({
      account: address(0x2EAeb1c783BAe3883B046cfAddEd0b89Bf53CaBC),
      value: 1,
      total: 12
    }));

    _members.push(Member({
      account: address(0xb1f757B8ffDD0378E126d26DE168752cD8B535A8),
      value: 2,
      total: 12
    }));

    _members.push(Member({
      account: address(0x39236F8bC6e45BC7a9702C6219d4800e72a08f33),
      value: 4,
      total: 12
    }));
    _members.push(Member({
      account: address(0x869C4E314D252e71Fc73dbCe284947E3D307Bc4f),
      value: 4,
      total: 12
    }));
  }

  receive () external payable {
    require(_members.length > 0, "There are no members");
    for(uint i = 0; i < _members.length; i++) {
      Member storage member = _members[i];
      _transfer(member.account, msg.value * member.value / member.total);
    }
  }

  function members() external view returns (Member[] memory) {
    return _members;
  }

  function release(address account, address token) public virtual {
    Member storage member = _members[0];
    bool isFound = false;
    for (uint256 i = 0; i < _members.length; i++) {
      if (_members[i].account == account) {
        member = _members[i];
        isFound = true;
      }
    }
    require(
      isFound, "TokenPaymentSplitter: account has no shares"
    );
  
    uint256 tokenTotalReceived = IERC20(token).balanceOf(address(this)) + _tokenInfo[token].totalReleased;
    uint256 payment = tokenTotalReceived * member.value / member.total - _tokenInfo[token].totalReleasedToAccount[account];
    require(payment != 0, "TokenPaymentSplitter: account is not due payment");

    _tokenInfo[token].totalReleasedToAccount[account] = _tokenInfo[token].totalReleasedToAccount[account] + payment;
    _tokenInfo[token].totalReleased = _tokenInfo[token].totalReleased + payment;
    IERC20(token).safeTransfer(account, payment);
  }

  // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
  error TransferFailed();
  function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
  }
}