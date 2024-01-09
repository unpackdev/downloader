// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20.sol";
import "./Ownable.sol";
import "./TokenTimelock.sol";

/**
 * $PREY token contract
 */
contract Prey is ERC20, Ownable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) public controllers;
  
  // the total amount allocated for developers
  uint constant developerTokenAmount = 600000000 ether;

  // the total amount allocated for community rewards
  uint constant communityTokenAmount = 2000000000 ether;

  // the total amount of tokens staked in the forest to yeild
  uint constant forestTokenAmount = 2400000000 ether;
  
  // the amount of $PREY tokens community has yielded
  uint mintedByCommunity;
  // the amount of $PREY tokens staked and yielded in the forest
  uint mintedByForest;

  /**
   * Contract constructor function
   * @param developerAccount The address that receives locked $PREY rewards for developers, in total 600 million
   */
  constructor(address developerAccount) ERC20("Prey", "PREY") {

    // create contract to lock $PREY token for 2 years (732 days in total) for developers, after which there is a 10 months(300 days in total) vesting schedule to release 600 million tokens
    TokenTimelock timelock = new TokenTimelock(this, developerAccount, block.timestamp + 732 days, 300 days, developerTokenAmount);
    _mint(address(timelock), developerTokenAmount);
    controllers[_msgSender()] = true;
  }
  /**
   * the function mints $PREY tokens to community members, effectively controls maximum yields
   * @param account mint $PREY to account
   * @param amount $PREY amount to mint
   */
  function mintByCommunity(address account, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    require(mintedByCommunity + amount <= communityTokenAmount, "No mint out");
    mintedByCommunity = mintedByCommunity + amount;
    _mint(account, amount);
  }

  /**
   * the function mints $PREY tokens to community members, effectively controls maximum yields
   * @param accounts mint $PREY to accounts
   * @param amount $PREY amount to mint
   */
  function mintsByCommunity(address[] calldata accounts, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    require(mintedByCommunity + (amount * accounts.length) <= communityTokenAmount, "No mint out");
    mintedByCommunity = mintedByCommunity + (amount * accounts.length);
    for (uint256 i = 0; i < accounts.length; i++) {
      _mint(accounts[i], amount);
    }
  }

  /**
   * the function mints $PREY tokens by the forest, effectively controls maximum yields
   * @param account mint $PREY to account
   * @param amount $PREY amount to mint
   */
  function mintByForest(address account, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    require(mintedByForest + amount <= forestTokenAmount, "No mint out");
    mintedByForest = mintedByForest + amount;
    _mint(account, amount);
  }

  /**
   * burn $PREY token by controller
   * @param account account holds $PREY token
   * @param amount the amount of $PREY token to burn
   */
  function burn(address account, uint256 amount) external {
    require(controllers[_msgSender()], "Only controllers can mint");
    _burn(account, amount);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

}