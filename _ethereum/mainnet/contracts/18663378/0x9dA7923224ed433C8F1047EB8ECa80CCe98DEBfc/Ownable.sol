// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

///@title Ownable contract
/// @notice Simple 2step owner authorization combining solmate and OZ implementation
abstract contract Ownable {
  /*//////////////////////////////////////////////////////////////
                             STORAGE
    //////////////////////////////////////////////////////////////*/

  ///@notice Address of the owner
  address public owner;

  ///@notice Address of the pending owner
  address public pendingOwner;

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event OwnershipTransferred(address indexed user, address indexed newOner);
  event OwnershipTransferStarted(address indexed user, address indexed newOwner);
  event OwnershipTransferCanceled(address indexed pendingOwner);

  /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/

  error Unauthorized();

  /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(address _owner) {
    owner = _owner;

    emit OwnershipTransferred(address(0), _owner);
  }

  /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

  ///@notice Transfer ownership to a new address
  ///@param newOwner address of the new owner
  ///@dev newOwner have to acceptOwnership
  function transferOwnership(address newOwner) external onlyOwner {
    pendingOwner = newOwner;
    emit OwnershipTransferStarted(msg.sender, pendingOwner);
  }

  ///@notice NewOwner accept the ownership, it transfer the ownership to newOwner
  function acceptOwnership() external {
    if (msg.sender != pendingOwner) revert Unauthorized();
    address oldOwner = owner;
    owner = pendingOwner;
    delete pendingOwner;
    emit OwnershipTransferred(oldOwner, owner);
  }

  ///@notice Cancel the ownership transfer
  function cancelTransferOwnership() external onlyOwner {
    emit OwnershipTransferCanceled(pendingOwner);
    delete pendingOwner;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized();
    _;
  }
}
