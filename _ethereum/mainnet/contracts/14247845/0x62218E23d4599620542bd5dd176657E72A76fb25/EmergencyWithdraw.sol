// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";

/**
 * @title Emergency withdraw
 *
 * @notice This contract is the implementation if owner wants to withdraw any ERC20 token
 *
 * @dev This contract contains logic is only used by owner
 *
 * @author mavia.com, reviewed by King
 *
 * Copyright (c) 2021 Mavia
 */
contract EmergencyWithdraw is OwnableUpgradeable {
  event Received(address _sender, uint256 _amount);

  /**
   * @dev Allow contract to receive ethers
   */
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  /**
   * @dev Get the eth balance on the contract
   * @return eth balance
   */
  function fGetEthBalance() external view returns (uint256) {
    return address(this).balance;
  }

  /**
   * @dev Withdraw eth balance
   */
  function fEmergencyWithdrawEthBalance(address _pTo, uint256 _pAmount) external onlyOwner {
    require(_pTo != address(0), "Invalid to");
    payable(_pTo).transfer(_pAmount);
  }

  /**
   * @dev Get the token balance
   * @param _pTokenAddress token address
   */
  function fGetTokenBalance(address _pTokenAddress) external view returns (uint256) {
    IERC20 erc20 = IERC20(_pTokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
   * @dev Withdraw token balance
   * @param _pTokenAddress token address
   */
  function fEmergencyWithdrawTokenBalance(
    address _pTokenAddress,
    address _pTo,
    uint256 _pAmount
  ) external onlyOwner {
    require(_pAmount > 0, "Invalid amount");
    IERC20 erc20 = IERC20(_pTokenAddress);
    require(erc20.transfer(_pTo, _pAmount), "transfer failed");
  }
}
