// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./AddressUpgradeable.sol";

/**
 * @dev Contract meant to receive the royalties for a given
 * token of Piano King Private and then splitting it between
 * the minter and the creator when sending the funds
 * It is an implementation meant to be used via a proxy
 * in Piano King Private contract
 */
contract PianoKingPrivateSplitter is OwnableUpgradeable {
  using AddressUpgradeable for address payable;
  address private creator;
  address private minter;
  uint256 private minterRoyalties;
  uint256 private creatorRoyalties;

  function initiliaze(
    address _creator,
    address _minter,
    uint256 _minterRoyalties,
    uint256 _creatorRoyalties
  ) public initializer {
    __Ownable_init();
    creator = _creator;
    minter = _minter;
    minterRoyalties = _minterRoyalties;
    creatorRoyalties = _creatorRoyalties;
  }

  receive() external payable {}

  /**
   * @dev Send the royalties accumulated on the contract
   * to the minter and creator according to the royalties defined
   * when minting the token
   */
  function retrieveRoyalties() external onlyOwner {
    uint256 totalRoyalties = minterRoyalties + creatorRoyalties;
    // From 0 to 10000 using 2 decimals (550 => 5.5%)
    uint256 creatorPercentage = (creatorRoyalties * 10000) / totalRoyalties;
    // Send the right amount to the creator
    payable(creator).sendValue(
      (creatorPercentage * address(this).balance) / 10000
    );
    // Send the remaining balance to the minter
    payable(minter).sendValue(address(this).balance);
  }

  /**
   * @dev Gets the creator associated to this contract
   */
  function getCreator() external view returns (address) {
    return creator;
  }
}
