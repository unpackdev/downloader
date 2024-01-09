// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Receiver.sol";
import "./Math.sol";
import "./DateTime.sol";

/* ========== ERRORS ========== */

library Errors {
  string internal constant InvalidTimestamp = "invalid timestamp";
  string internal constant InvalidInput = "invalid input provided";
  string internal constant NoVestingSchedule =
    "sender has not been registered for a vesting schedule";
  string internal constant InsufficientTokenBalance =
    "contract does not have enough tokens to distribute";
}

/* ========== DATA STRUCTURES ========== */

// @notice A vesting schedule for an individual address.
struct VestingSchedule {
  uint256 lastClaim;
  uint16 monthsRemaining;
  uint32 tokensPerMonth;
}

contract Vesting is Ownable, ERC1155Receiver {
  /* ========== EVENTS ========== */

  event VestingTokensGranted(
    address indexed to,
    uint256 totalMonths,
    uint256 tokensPerMonth
  );
  event VestedTokensClaimed(
    address indexed by,
    uint256 monthsClaimed,
    uint256 amount
  );
  event VestingTokensRevoked(address indexed from);
  event RewardTokenSet(address tokenAddress, uint256 tokenId);
  event TokensWithdrawnFromContract(address indexed to, uint256 amount);

  /* ========== STATE VARIABLES ========== */

  address private _tokenAddress;
  uint256 private _tokenId;

  mapping(address => VestingSchedule) private _vestingSchedules;

  /* ========== CONSTRUCTOR ========== */

  constructor(address tokenAddress, uint256 tokenId) ERC1155Receiver() {
    _tokenAddress = tokenAddress;
    _tokenId = tokenId;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  // @notice Claim your vested tokens since last claiming timestamp.
  function claimTokens() external returns (uint256 tokensToClaim) {
    VestingSchedule storage userVestingSchedule = _vestingSchedules[msg.sender];

    uint256 monthsPassed = DateTime.diffMonths(
      _vestingSchedules[msg.sender].lastClaim,
      block.timestamp
    );

    // use uint16 because we can not claim more than the months remaining. avoid overflow later when assumptions are more complex.
    // explicit conversion here should be fine, since we already min() with a upscaled uint16 (monthsRemaining), so the range should fall within a single uint16
    uint16 monthsClaimed = uint16(
      Math.min(userVestingSchedule.monthsRemaining, monthsPassed)
    );

    if (monthsClaimed == 0) {
      return 0;
    } else {
      tokensToClaim =
        uint256(userVestingSchedule.tokensPerMonth) *
        monthsClaimed;
    }

    IERC1155 token = IERC1155(_tokenAddress);
    require(
      token.balanceOf(address(this), _tokenId) >= tokensToClaim,
      Errors.InsufficientTokenBalance
    );

    _vestingSchedules[msg.sender].lastClaim = block.timestamp;
    _vestingSchedules[msg.sender].monthsRemaining =
      _vestingSchedules[msg.sender].monthsRemaining -
      monthsClaimed;

    token.safeTransferFrom(
      address(this),
      msg.sender,
      _tokenId,
      tokensToClaim,
      "Claiming vested tokens"
    );
    emit VestedTokensClaimed(msg.sender, monthsClaimed, tokensToClaim);
  }

  // @notice Grant vesting tokens to a specified address.
  // @param toGrant Address to receive tokens on a vesting schedule.
  // @param numberOfMonths Number of months to grant tokens for.
  // @param tokensPerMonth Number of tokens to grant per month.
  function grantVestingTokens(
    address toGrant,
    uint16 numberOfMonths,
    uint32 tokensPerMonth
  ) external onlyOwner {
    require(toGrant != address(0), Errors.InvalidInput);
    _vestingSchedules[toGrant] = VestingSchedule(
      block.timestamp,
      numberOfMonths,
      tokensPerMonth
    );
    emit VestingTokensGranted(toGrant, numberOfMonths, tokensPerMonth);
  }

  // @notice Owner can withdraw tokens deposited into the contract.
  // @param count The number of tokens to withdraw.
  function withdrawTokens(uint256 count) external onlyOwner {
    IERC1155 token = IERC1155(_tokenAddress);
    require(
      token.balanceOf(address(this), _tokenId) >= count,
      Errors.InsufficientTokenBalance
    );

    token.safeTransferFrom(
      address(this),
      msg.sender,
      _tokenId,
      count,
      "Withdrawing tokens"
    );

    emit TokensWithdrawnFromContract(msg.sender, count);
  }

  // @notice Revoke vesting tokens from specified address.
  // @param revokeAddress The address to revoke tokens from.
  function revokeVestingTokens(address revokeAddress) external onlyOwner {
    _vestingSchedules[revokeAddress].tokensPerMonth = 0;
    _vestingSchedules[revokeAddress].monthsRemaining = 0;
    emit VestingTokensRevoked(revokeAddress);
  }

  /*
   * @notice Set the token to be used for vesting rewards.
   * @dev Token must implement ERC1155.
   * @param tokenAddress The address of the token contract.
   * @param tokenId The id of the token.
   */
  function setToken(address tokenAddress, uint256 id) external onlyOwner {
    _tokenAddress = tokenAddress;
    _tokenId = id;
    emit RewardTokenSet(tokenAddress, id);
  }

  /* ========== VIEW FUNCTIONS ========== */

  /*
   * @notice Get the vested token address and ID.
   */
  function getToken() external view returns (address, uint256) {
    return (_tokenAddress, _tokenId);
  }

  /*
   * @notice Get the vesting schedule for a specified address.
   * @param addr The address to get the schedule for.
   */
  function getVestingSchedule(address addr)
    external
    view
    returns (
      uint256 timestamp,
      uint16 monthsRemaining,
      uint32 tokensPerMonth
    )
  {
    VestingSchedule storage _vestingSchedule = _vestingSchedules[addr];
    return (
      _vestingSchedule.lastClaim,
      _vestingSchedule.monthsRemaining,
      _vestingSchedule.tokensPerMonth
    );
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external pure override returns (bytes4) {
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external pure override returns (bytes4) {
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }
}
