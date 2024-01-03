// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20.sol"; // Not upgradeable because we just need the interface

contract PaymentRegister is OwnableUpgradeable, PausableUpgradeable {
  event EthPaymentMade(address _from, uint256 _value, uint256 _data);
  event ERC20PaymentMade(address _tokenAddress, address _from, uint256 _value, uint256 _data);
  
  /**
   * @dev Initializer function.
   *
   */
  function initialize() public initializer {
    OwnableUpgradeable.__Ownable_init();
    PausableUpgradeable.__Pausable_init();
  }
  
  // Reject any incoming ETH Simple Send payment
  receive() external payable {
    revert("This contract cannot be paid directly");
  }

  // allow payments with a valid data parameter
  function makePayment (uint256 _data) whenNotPaused public payable {
    require(msg.sender != owner());
    require(msg.value != 0);
    require(_data != 0);
    emit EthPaymentMade(msg.sender, msg.value, _data);
  }
  
  function pullApprovedToken (address _tokenAddress, address _from, uint256 _amount, uint256 _data) public {
    require(_tokenAddress != address(0x0));
    require(_amount != 0);
    require(_data != 0);
    IERC20 token = IERC20(_tokenAddress);
    address to = address(this);
    token.transferFrom(_from, to, _amount);
    emit ERC20PaymentMade(_tokenAddress, _from, _amount, _data);
  }

  function withdrawFunds (address payable _target) onlyOwner public {
    require (_target != address(0x0));
    _target.transfer(address(this).balance);
  }
  
  function withdrawToken (address _tokenAddress, address _target, uint256 _amount) onlyOwner public {
    require(_tokenAddress != address(0x0));
    require (_target != address(0x0));
    IERC20 token = IERC20(_tokenAddress);
    token.transfer(_target, _amount);
  }
}