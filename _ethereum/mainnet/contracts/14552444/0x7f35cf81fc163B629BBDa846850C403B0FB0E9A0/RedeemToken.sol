// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeTransfer.sol";
import "./SafeMath.sol";
import "./Context.sol";

contract RedeemToken is SafeTransfer, Context {
  using SafeMath for uint256;

  struct Item {
    uint256 amount;
    uint256 unlockTime;
    uint256 userIndex;
    address owner;
  }

  /// @notice tracking assets belonging to a particular user
  struct UserInfo {
    mapping(address => mapping(address => uint256[])) lockToItems;
  }

  mapping(address => UserInfo) users;
  /// @notice id number of the vault deposit
  uint256 public depositId;
  /// @notice an array of all the deposit Ids
  uint256[] public allDepositIds;
  /// @notice mapping from item Id to the Item struct
  mapping(uint256 => Item) public lockedItem;

  event onLock(address tokenAddress, address user, uint256 amount);
  event onUnlock(address tokenAddress, uint256 amount);

  /**
   * @notice Locking tokens in the vault
   * @param _tokenAddress Address of the token locked
   * @param _amount Number of tokens locked
   * @param _unlockTime Timestamp number marking when tokens get unlocked
   * @param _withdrawer Address where tokens can be withdrawn after unlocking
   */
  function lockTokens(
    address _tokenAddress,
    address _privateSaleAddress,
    uint256 _amount,
    uint256 _unlockTime,
    address _withdrawer
  )
    public returns (uint256 _id)
  {
    require(_amount > 0, "RedeemToken: token amount is Zero");
    require(_unlockTime < 10000000000, "ReddemToken: timestamp should be in seconds");
    require(_withdrawer != address(0), "ReddemToken: withdrawer is zero address");
    _safeTransferFrom(_tokenAddress, _msgSender(), _amount);

    _id = ++depositId;

    lockedItem[_id].amount = _amount;
    lockedItem[_id].unlockTime = _unlockTime;
    lockedItem[_id].owner = _withdrawer;

    allDepositIds.push(_id);

    UserInfo storage userItem = users[_withdrawer];
    userItem.lockToItems[_tokenAddress][_privateSaleAddress].push(_id);
    uint256 userIndex = userItem.lockToItems[_tokenAddress][_privateSaleAddress].length - 1;
    lockedItem[_id].userIndex = userIndex;

    emit onLock(_tokenAddress, _msgSender(), lockedItem[_id].amount);
  }

  /**
   * @notice Withdrawing tokens from the vault
   * @param _tokenAddress Address of the token to withdraw
   * @param _index Index number of the list with Ids
   * @param _id Id number
   * @param _amount Number of tokens to withdraw
   */
  function withdrawTokens(
    address _tokenAddress,
    address _privateSaleAddress,
    uint256 _index,
    uint256 _id,
    uint256 _amount,
    address _recipient
  ) external {
    require(_amount > 0, "RedeemToken: token amount is zero");
    uint256 id = users[_recipient].lockToItems[_tokenAddress][_privateSaleAddress][_index];
    Item storage userItem = lockedItem[id];
    require(id == _id && userItem.owner == _recipient, "RedeemToken: not found");
    require(userItem.unlockTime < block.timestamp, "RedeemToken: not unlocked yet");
    userItem.amount = userItem.amount.sub(_amount);

    _safeTransfer(_tokenAddress, _recipient, _amount);
    emit onUnlock(_tokenAddress, _amount);
  }

  /**
   * @notice Retrieve data from the item under user index number
   * @param _index Index number of the list with item ids
   * @param _tokenAddress Address of the token corresponding to this item
   * @param _user User address
   * @return Items token amount number, Items unlock timestamp, Items owner address, Items Id number
   */
  function getItemAtUserIndex(
    uint256 _index,
    address _tokenAddress,
    address _privateSaleAddress,
    address _user
  )
    external view returns (uint256, uint256, address, uint256)
  {
    uint256 id = users[_user].lockToItems[_tokenAddress][_privateSaleAddress][_index];
    Item storage item = lockedItem[id];
    return (item.amount, item.unlockTime, item.owner, id);
  }

  /**
   * @notice Retrieve all the data from Item struct under given Id.
   * @param _id Id number.
   * @return All the data for this Id (token amount number, unlock time number, owner address and user index number)
   */
  function getLockedItemAtId(uint256 _id) external view returns (uint256, uint256, address, uint256, uint256) {
      Item storage item = lockedItem[_id];
      return (item.amount, item.unlockTime, item.owner, item.userIndex, _id);
  }

  /**
   * @notice Get locked item's ids of the specified user
   * @param _user User address
   * @param _tokenAddress Address token
   */
  function getLockedItemIdsOfUser(address _user, address _tokenAddress, address _privateSaleAddress) external view returns (uint256[] memory) {
    UserInfo storage user = users[_user];
    return user.lockToItems[_tokenAddress][_privateSaleAddress];
  }
}