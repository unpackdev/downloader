// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./IERC20Metadata.sol";

import "./BenNationPool.sol";
import "./BenNationVault.sol";

/**
 * @title Factory for creating BenNation pools and vaults
 * @author Ben Coin Collective
 * @notice This contract is responsible for deploying new BenNation pools and vaults.
 * @dev It is built upon the Pancake SmartChefFactory V2 contract, and updated to include
 * the ability to deploy vaults where the same staked and reward tokens are used.
 */
contract BenNationFactory is Ownable {
  event NewBenNationContracts(address indexed benNationPool, address indexed vault);

  /**
   * @notice Deploy the pool
   * @param _stakedToken: staked token address
   * @param _rewardToken: reward token address
   * @param _rewardPerBlock: reward per block (in rewardToken)
   * @param _startBlock: start block
   * @param _endBlock: end block
   * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
   * @param _numberBlocksForUserLimit: block numbers available for user limit (after start block)
   * @param _admin: admin address with ownership of the pool
   * @dev Only callable by owner. Can be used to deploy a new pool.
   */
  function deployPool(
    IERC20Metadata _stakedToken,
    IERC20Metadata _rewardToken,
    uint256 _rewardPerBlock,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _poolLimitPerUser,
    uint256 _numberBlocksForUserLimit,
    address _admin
  ) external onlyOwner {
    bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startBlock));
    address benNationPoolAddress;
    {
      bytes memory bytecode = type(BenNationPool).creationCode;

      assembly ("memory-safe") {
        benNationPoolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
      }
    }

    // Vaults are required to separate user funds and reward funds when
    // both the staked and reward tokens are the same.
    address vault;
    if (_stakedToken == _rewardToken) {
      bytes memory bytecode = type(BenNationVault).creationCode;
      assembly ("memory-safe") {
        vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
      }
      BenNationVault(vault).transferOwnership(benNationPoolAddress);
    }

    BenNationPool(benNationPoolAddress).initialize(
      _stakedToken,
      _rewardToken,
      _rewardPerBlock,
      _startBlock,
      _endBlock,
      _poolLimitPerUser,
      _numberBlocksForUserLimit,
      vault,
      _admin
    );

    emit NewBenNationContracts(benNationPoolAddress, vault);
  }
}
