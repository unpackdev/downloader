// SPDX-License-Identifier: MIT

/*
 * Contract by pr0xy.io
 *   _ ______ _____  ________  ___
 *  | ||  _  \  _  ||  _  |  \/  |
 * / __) | | | | | || | | | .  . |
 * \__ \ | | | | | || | | | |\/| |
 * (   / |/ /\ \_/ /\ \_/ / |  | |
 *  |_||___/  \___/  \___/\_|  |_/
 */

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";
import "./ERC20Burnable.sol";

// Collection Interface
interface DoomersGeneration {
  function ownerOf(uint tokenId) external view returns (address);
}

contract DoomToken is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20Votes {

  // Time that must go by after claiming tokens
  uint256 public coolOffPeriod;

  // Storage of mint amounts for each generation
  mapping(uint256 => uint256) public amounts;

  // Storage of contract addresses for each generation
  mapping(uint256 => address) public contracts;

  // Storage of tokens which have been claimed
  mapping(uint256 => mapping(uint256 => uint256)) public coolOffPeriods;

  // Storage of tokens which have been claimed
  mapping(uint256 => mapping(uint256 => mapping(address => bool))) public claims;

  constructor() ERC20("DoomToken", "DOOM") ERC20Permit("DoomToken") {}

  // Sets the amount of $DOOM to reward for a given `_generation`
  function setAmount(uint256 _generation, uint256 _amount) external onlyOwner {
    amounts[_generation] = _amount;
  }

  // Sets the contract address for a given `_generation`
  function setContract(uint256 _generation, address _contract) external onlyOwner {
    contracts[_generation] = _contract;
  }

  // Sets the `coolOffPeriod` to be used in `claim()`
  function setCoolOffPeriod(uint256 _coolOffPeriod) external onlyOwner {
    coolOffPeriod = _coolOffPeriod;
  }

  // Returns if a `_wallet` has claimed a given `_tokenId` for a given `_generation`
  function isClaimed(uint256 _generation, uint256 _tokenId, address _wallet) external view returns (bool) {
    return claims[_generation][_tokenId][_wallet];
  }

  // Minting function for holders of any Doomers collection
  function claim(uint256 _generation, uint256 _tokenId) external {
    require(!claims[_generation][_tokenId][msg.sender], 'Tokens Claimed');
    require(block.timestamp > coolOffPeriods[_generation][_tokenId], 'Cool Off');
    require(DoomersGeneration(contracts[_generation]).ownerOf(_tokenId) == msg.sender, 'Sender Denied');

    _mint(msg.sender, amounts[_generation]);

    // Blacklist minter for given generation and token
    claims[_generation][_tokenId][msg.sender] = true;

    // Set cool off period
    coolOffPeriods[_generation][_tokenId] = block.timestamp + coolOffPeriod;
  }

  // Mint function for owner
  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }

  // Override function for post token transfer
  function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  // Override function for minting
  function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  // Override function for burning
  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }
}
