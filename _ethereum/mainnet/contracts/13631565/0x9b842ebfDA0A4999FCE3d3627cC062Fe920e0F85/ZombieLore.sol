/*
 ██▓    ▒█████   ██▀███  ▓█████
▓██▒   ▒██▒  ██▒▓██ ▒ ██▒▓█   ▀
▒██░   ▒██░  ██▒▓██ ░▄█ ▒▒███  
▒██░   ▒██   ██░▒██▀▀█▄  ▒▓█  ▄
░██████░ ████▓▒░░██▓ ▒██▒░▒████
░ ▒░▓  ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░░░ ▒░ 
░ ░ ▒    ░ ▒ ▒░   ░▒ ░ ▒░ ░ ░  
  ░ ░  ░ ░ ░ ▒     ░   ░    ░  
    ░      ░ ░     ░        ░  
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC20.sol";
import "./ERC721.sol";

// Interface with staking contract
interface ITheCrypt {
  function depositsOf(address account) external view returns (uint256[] memory);
}

contract ZombieLore is Pausable, Ownable, ReentrancyGuard {

  // External addresses
  address public zombiezAddress;
  address public fleshAddress;
  address public stakingAddress;

  // Cost of $FLESH per update
  uint256 public updateCost = 50 ether;

  // Store offchain metadata key
  mapping(uint256 => string) public metadataKeyMap;

  // Default metadata key value
  string private constant DEFAULT = "default";

  // Events when lore changes
  event LoreUpdated(uint256 zombieId, string metadataKey);
  event LoreCleared(uint256 zombieId);

  constructor(address _zombiezAddress, address _fleshAddress, address _stakingAddress) {
    zombiezAddress = _zombiezAddress;
    fleshAddress = _fleshAddress;
    stakingAddress = _stakingAddress;
    _pause();
  }

  // Modifier to ensure ownership (direct or staked)
  modifier isZombieOwner(uint256 zombieId) {
    address owner = IERC721(zombiezAddress).ownerOf(zombieId);
    if (owner != msg.sender) {
      // Check if owner staked the Zombie
      bool foundZombie = false;
      if (owner == stakingAddress) {
        uint256[] memory zombiez = ITheCrypt(stakingAddress).depositsOf(msg.sender);
        uint zombieCount = zombiez.length;
        for (uint i = 0; i < zombieCount; i++) {
          if (zombieId == zombiez[i]) {
            foundZombie = true;
            break;
          }
        }
      }
      require(foundZombie, "permission denied");
    }

    _; // run remainder of function
  }

  // Transfer FLESH cost to contract
  function payFleshCost() internal {
    IERC20 fleshContract = IERC20(fleshAddress);

    // Validate FLESH is approved to be transferred
    uint256 allowance = fleshContract.allowance(msg.sender, address(this));
    require(updateCost <= allowance, "insufficient approved amount");

    // Transfer cost
    fleshContract.transferFrom(msg.sender, address(this), updateCost);
  }

  // Function to rewrite lore (metadataKey is an off-chain id to store metadata)
  function setMetadataKey(uint256 zombieId, string calldata metadataKey) external isZombieOwner(zombieId) whenNotPaused nonReentrant {
    payFleshCost();
    metadataKeyMap[zombieId] = metadataKey;
    emit LoreUpdated(zombieId, metadataKey);
  }

  // Return the metadata back to its original state (0 = default)
  function resetMetadata(uint256 zombieId) external isZombieOwner(zombieId) whenNotPaused nonReentrant {
    payFleshCost();
    delete metadataKeyMap[zombieId];
    emit LoreCleared(zombieId);
  }

  // Get the current key for token (used by the API)
  function getMetadataKey(uint256 zombieId) external view returns(string memory) {
    string memory metadataKey = metadataKeyMap[zombieId];
    if (bytes(metadataKey).length == 0) {
      return DEFAULT; // return DEFAULT for empty values 
    } else {
      return metadataKey;
    }
  }

  // Withdraw $FLESH to address
  function withdrawFlesh(address recipient) external onlyOwner {
    uint256 balance = IERC721(fleshAddress).balanceOf(address(this));
    IERC20(fleshAddress).transferFrom(msg.sender, recipient, balance);
  }

  // Allow owners to change metadata if compelled
  function overrideMetadata(uint256 zombieId) external onlyOwner {
    delete metadataKeyMap[zombieId];
    emit LoreCleared(zombieId);
  }

  // Accessor methods for pausing
  function pause() external onlyOwner { _pause(); }
  function unpause() external onlyOwner { _unpause(); }
}
