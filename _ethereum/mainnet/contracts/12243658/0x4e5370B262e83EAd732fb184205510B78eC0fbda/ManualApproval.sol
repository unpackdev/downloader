// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";

import "./ITransferRules.sol";
import "./SRC20.sol";

/*
 * @title ManualApproval contract
 * @dev On-chain transfer rules that handle transfer request/execution for
 * grey-listed accounts
 */
contract ManualApproval is Ownable {
  struct TransferRequest {
    address from;
    address to;
    uint256 value;
  }

  uint256 public requestCounter = 1;
  SRC20 public src20;

  mapping(uint256 => TransferRequest) public transferRequests;
  mapping(address => bool) public greylist;

  event AccountGreylisted(address account, address sender);
  event AccountUnGreylisted(address account, address sender);
  event TransferRequested(uint256 indexed requestId, address from, address to, uint256 value);

  event TransferApproved(
    uint256 indexed requestId,
    address indexed from,
    address indexed to,
    uint256 value
  );

  event TransferDenied(
    uint256 indexed requestId,
    address indexed from,
    address indexed to,
    uint256 value
  );

  function approveTransfer(uint256 _requestId) external onlyOwner returns (bool) {
    TransferRequest memory req = transferRequests[_requestId];

    require(src20.executeTransfer(address(this), req.to, req.value), 'SRC20 transfer failed');

    delete transferRequests[_requestId];
    emit TransferApproved(_requestId, req.from, req.to, req.value);
    return true;
  }

  function denyTransfer(uint256 _requestId) external returns (bool) {
    TransferRequest memory req = transferRequests[_requestId];
    require(
      owner() == msg.sender || req.from == msg.sender,
      'Not owner or sender of the transfer request'
    );

    require(
      src20.executeTransfer(address(this), req.from, req.value),
      'SRC20: External transfer failed'
    );

    delete transferRequests[_requestId];
    emit TransferDenied(_requestId, req.from, req.to, req.value);

    return true;
  }

  function isGreylisted(address _account) public view returns (bool) {
    return greylist[_account];
  }

  function greylistAccount(address _account) external onlyOwner returns (bool) {
    greylist[_account] = true;
    emit AccountGreylisted(_account, msg.sender);
    return true;
  }

  function bulkGreylistAccount(address[] calldata _accounts) external onlyOwner returns (bool) {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      greylist[account] = true;
      emit AccountGreylisted(account, msg.sender);
    }
    return true;
  }

  function unGreylistAccount(address _account) external onlyOwner returns (bool) {
    delete greylist[_account];
    emit AccountUnGreylisted(_account, msg.sender);
    return true;
  }

  function bulkUnGreylistAccount(address[] calldata _accounts) external onlyOwner returns (bool) {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      delete greylist[account];
      emit AccountUnGreylisted(account, msg.sender);
    }
    return true;
  }

  function _requestTransfer(
    address _from,
    address _to,
    uint256 _value
  ) internal returns (bool) {
    require(src20.executeTransfer(_from, address(this), _value), 'SRC20 transfer failed');

    transferRequests[requestCounter] = TransferRequest(_from, _to, _value);

    emit TransferRequested(requestCounter, _from, _to, _value);
    requestCounter = requestCounter + 1;

    return true;
  }
}
