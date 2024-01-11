//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

/// @title RAC Token Distributor Smart Contract
/// @author HIFI Labs Inc.
/// @notice This contract allows an address to claim tokens if they have any pending tokens to claim

contract RACTokenDistributor is Ownable {
  /// @notice instantiates RAC token
  IERC20 racInstance;

  /// @notice maps and address to an withdrawable rac token amount
  mapping(address => uint256) public claimableTokensPerAddress;

  /// @notice Emitted when user can claim tokens
  /// @param user The address of user
  /// @param amountClaimable amount of claimable tokens for the user
  event ClaimableRACTokens(address indexed user, uint256 amountClaimable);

  /// @notice Emitted when user claims
  /// @param user The address of user
  /// @param amountClaimed amount claimed
  event RACClaimed(address indexed user, uint256 amountClaimed);

  /// @notice create a constructor to initialize racInstance
  /// @param erc20Address The address of erc20 token
  constructor(address erc20Address) {
    racInstance = IERC20(erc20Address);
  }

  /// @notice withdraws contract rac token balance
  /// @param _address address to send rac tokens to
  /// @dev this function is callable by only admin
  function withdrawContractBalance(address _address) external onlyOwner {
    uint256 contractBalance = racInstance.balanceOf(address(this));

    require(

      contractBalance > 0,
      "there are no tokens to transfer"
    );

    racInstance.transfer(_address, contractBalance);
  }

  /// @notice batch set claimable tokens per address
  /// @param _users arrays of users
  /// @param _claimableTokens arrays of subscription types which users will be mapped to respectively
  /// @param _shouldAccumulate specifies if new value should be added with existing claimable balance
  /// @dev this function is callable by only admin
  function batchUpdateClaimableRACTokensPerAddress(
    address[] calldata _users,
    uint256[] calldata _claimableTokens,
    bool _shouldAccumulate
  ) external onlyOwner {
    require(
      _users.length == _claimableTokens.length,
      "users and claimableTokens length mismatch"
    );

    for (uint256 i = 0; i < _users.length; i++) {
      if (_shouldAccumulate) {
        claimableTokensPerAddress[_users[i]] += _claimableTokens[i];
      } else {
        claimableTokensPerAddress[_users[i]] = _claimableTokens[i];
      }
      emit ClaimableRACTokens(_users[i], _claimableTokens[i]);
    }
  }

  /// @notice function to claim available RAC Tokens
  function claimRACTokens() external {
    uint256 claimableTokens = claimableTokensPerAddress[msg.sender];

    require(
      claimableTokens > 0,
      "there are no tokens to claim for this address"
    );

    claimableTokensPerAddress[msg.sender] = 0;

    bool sent = racInstance.transfer(msg.sender, claimableTokens);

    require(sent, "Token transfer failed");

    emit RACClaimed(msg.sender, claimableTokens);
  }
}
