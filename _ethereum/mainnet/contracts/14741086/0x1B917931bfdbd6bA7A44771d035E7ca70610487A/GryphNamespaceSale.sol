// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

import "./INamespaceMinter.sol";

//
//     ______  _______   ____  ____   _______  ____  ____  
//   .' ___  ||_   __ \ |_  _||_  _| |_   __ \|_   ||   _| 
//  / .'   \_|  | |__) |  \ \  / /     | |__) | | |__| |   
//  | |   ____  |  __ /    \ \/ /      |  ___/  |  __  |   
//  \ `.___]  |_| |  \ \_  _|  |_  _  _| |_    _| |  | |_  
//   `._____.'|____| |___||______|(_)|_____|  |____||____| 
//
//  CROSS CHAIN NFT MARKETPLACE
//  https://www.gry.ph/
//

// ============ Errors ============

error InvalidCall();

contract GryphNamespaceSale is Ownable, ReentrancyGuard {

  // ============ Storage ============

  //namespace registry
  INamespaceMinter public registry;
  //where 5000 = 50.00%
  uint256 public commission = 5000;
  //amount of rewards needed to redeem
  uint256 public minimumRedeem = 0.1 ether;
  //mapping of referrers to rewards
  mapping(address => uint256) public rewards;
  //amount of eth received that can be withdrawn
  uint256 private _received;

  // ============ Deploy ============

  /**
   * @dev Sets contract registry
   */
  constructor(INamespaceMinter _registry) {
    registry = _registry;
  }

  // ============ Write Methods ============

  /**
   * @dev Allows anyone to buy a name
   */
  function buy(
    address recipient, 
    string memory namespace,
    address referrer
  ) external payable {
    //get the length of name
    uint256 length = bytes(namespace).length;
    //disallow length length less than 4
    if (length < 3) revert InvalidCall();
    //get prices
    uint64[4] memory prices = _prices();
    //get index
    uint256 index = length - 3;
    if (index >= prices.length) {
      index = prices.length - 1;
    }
    //check price
    if (msg.value < prices[index]) revert InvalidCall();
    //if valid address and not a contract
    if (referrer != address(0) && referrer.code.length == 0) {
      //not possible to underflow (unless price changes)
      unchecked {
        //assign rewards
        uint256 reward = (prices[index] * commission) / 10000;
        rewards[referrer] += reward;
        _received += msg.value - reward;
      }
    } else {
      _received += msg.value;
    }
    //okay to mint
    registry.mint(recipient, namespace);
  }

  /**
   * @dev Lets referrer withdraw their amount
   */
  function redeem(address recipient) external nonReentrant {
    if (rewards[recipient] < minimumRedeem) revert InvalidCall();
    //send value
    Address.sendValue(payable(recipient), rewards[recipient]);
    //reset rewards (make sure nonReentrant)
    rewards[recipient] = 0;
  }

  // ============ Admin Methods ============

  /**
   * @dev Updates the minimum redeem. This will solve for 
   * locked funds in the future
   */
  function updateMinimumRedeem(uint256 minimum) external onlyOwner {
    minimumRedeem = minimum;
  }

  /**
   * @dev Updates the commission.
   */
  function updateCommission(uint256 _commission) external onlyOwner {
    commission = _commission;
  }

  /**
   * @dev Sends the entire contract balance to a `recipient`
   */
  function withdraw(address recipient) 
    external nonReentrant onlyOwner
  {
    //send the received
    Address.sendValue(payable(recipient), _received);
    //reset received
    _received = 0;
  }

  // ============ Private Methods ============

  function _prices() private pure returns(uint64[4] memory) {
    return [
      0.100 ether, //3 letters
      0.050 ether, //4 letters
      0.010 ether, //5 letters 
      0.005 ether  //6 letters
    ];
  }
}