// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";

/**
 * @dev Contract holding the funds for the DAOs
 */
contract PianoKingFunds is Ownable {
  using Address for address payable;

  address private firstDAO;
  address private secondDAO;

  /**
   * @dev Allow the contract to receive funds from anyone
   */
  receive() external payable {}

  /**
   * @dev Set the addresses of the DAOs
   */
  function setDAOAddresses(address _firstDao, address _secondDao)
    external
    onlyOwner
  {
    require(
      _firstDao != address(0) && _secondDao != address(0),
      "Invalid address"
    );
    firstDAO = _firstDao;
    secondDAO = _secondDao;
  }

  /**
   * @dev Send the funds accumulated by the contract to the DAOs
   */
  function retrieveFunds() external onlyOwner {
    // Check that the DAOs addresses have been set
    require(
      firstDAO != address(0) && secondDAO != address(0),
      "DAOs not active"
    );
    // We split evenly the funds between the 2 DAOs
    uint256 amountToSend = address(this).balance / 2;
    // And send it to each one of them
    payable(firstDAO).sendValue(amountToSend);
    payable(secondDAO).sendValue(amountToSend);
  }
}
