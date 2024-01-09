// SPDX-License-Identifier: MIT

/*
 * Contract by pr0xy.io
 *   _  _____  _     _____  ________  ___
 *  | ||  __ \| |   |  _  ||  _  |  \/  |
 * / __) |  \/| |   | | | || | | | .  . |
 * \__ \ | __ | |   | | | || | | | |\/| |
 * (   / |_\ \| |___\ \_/ /\ \_/ / |  | |
 *  |_| \____/\_____/\___/  \___/\_|  |_/
 */

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20Burnable.sol";

// Collections Interface
interface DoomersGeneration {
  function ownerOf(uint tokenId) external view returns (address);
}

contract GloomToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {

  // Storage of numerators for each generation
  mapping(uint256 => uint256) public numerators;

  // Storage of numerators for each generation
  mapping(uint256 => uint256) public denominators;

  // Storage of contract addresses for each generation
  mapping(uint256 => address) public contracts;

  // Storage of the block a token has been staked at
  mapping(uint256 => mapping(uint256 => address)) public depositers;

  // Storage of the block a token has been staked at
  mapping(uint256 => mapping(uint256 => uint256)) public depositBlocks;

  constructor() ERC20("GloomToken", "GLOOM") {}

  // Sets the contract address for a given `_generation`
  function setContract(uint256 _generation, address _contract) external onlyOwner {
    contracts[_generation] = _contract;
  }

  // Sets the denominator of the rate of $GLOOM to reward for a given `_generation`
  function setDenominator(uint256 _generation, uint256 _denominator) external onlyOwner {
    denominators[_generation] = _denominator;
  }

  // Sets the numerator of the rate of $GLOOM to reward for a given `_generation`
  function setNumerator(uint256 _generation, uint256 _numerator) external onlyOwner {
    numerators[_generation] = _numerator;
  }

  // Mint function for owner
  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }

  // Allows token owners to claim $GLOOM from their staked tokens
  function claim(uint256[] calldata _generations, uint256[] calldata _tokenIds) external nonReentrant() {
    require(_generations.length == _tokenIds.length, 'Invalid Inputs');

    uint256 reward;

    for(uint256 i; i < _generations.length; i++){
      require(depositers[_generations[i]][_tokenIds[i]] == msg.sender, 'False Deposit');
      require(DoomersGeneration(contracts[_generations[i]]).ownerOf(_tokenIds[i]) == msg.sender, 'Sender Denied');

      // Calculate staking reward
      uint256 stakingPeriod = block.timestamp - depositBlocks[_generations[i]][_tokenIds[i]];
      reward += (stakingPeriod * numerators[_generations[i]] / denominators[_generations[i]]);

      // Reset staking period
      depositers[_generations[i]][_tokenIds[i]] = msg.sender;
      depositBlocks[_generations[i]][_tokenIds[i]] = block.timestamp;
    }

    // if there is a reward, mint it to the `sender`
    _mint(msg.sender, reward * 1 ether);
  }

  // Returns a point in time rewards amount for provided tokens
  function estimate(uint256[] calldata _generations, uint256[] calldata _tokenIds) external view returns (uint256){
    require(_generations.length == _tokenIds.length, 'Invalid Inputs');

    uint256 reward;

    for(uint256 i; i < _generations.length; i++){
      require(depositBlocks[_generations[i]][_tokenIds[i]] > 0 && depositers[_generations[i]][_tokenIds[i]] == msg.sender, 'Token Not Staked');
      uint256 stakingPeriod = block.timestamp - depositBlocks[_generations[i]][_tokenIds[i]];
      reward += (stakingPeriod * numerators[_generations[i]] / denominators[_generations[i]]);
    }

    return reward * 1 ether;
  }

  // Allows token owners to stake their tokens
  function stake(uint256[] calldata _generations, uint256[] calldata _tokenIds) external nonReentrant() {
    require(_generations.length == _tokenIds.length, 'Invalid Inputs');

    for(uint256 i; i < _generations.length; i++){
      require(DoomersGeneration(contracts[_generations[i]]).ownerOf(_tokenIds[i]) == msg.sender, 'Sender Denied');
      require(!(depositBlocks[_generations[i]][_tokenIds[i]] > 0 && depositers[_generations[i]][_tokenIds[i]] == msg.sender), 'Token Staked');

      depositers[_generations[i]][_tokenIds[i]] = msg.sender;
      depositBlocks[_generations[i]][_tokenIds[i]] = block.timestamp;
    }
  }
}
