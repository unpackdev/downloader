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
import "./ECDSA.sol";

// Interface with staking contract
interface ITheCrypt {
  function depositsOf(address account) external view returns (uint256[] memory);
}

contract ZombieLore is Pausable, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  // External addresses
  address private immutable zombiezAddress;
  address private immutable fleshAddress;
  address private immutable stakingAddress;

  // Map of token to metadata key
  mapping(uint256 => string) private metadataKeyMap;

  // Default metadata key value
  string private constant DEFAULT = "default";

  // Public key of authorized signature
  address public signVerifier;

  // Cost of $FLESH to reset metadata
  uint256 public resetCost = 100 ether;

  // Events when lore changes
  event LoreUpdated(uint256 zombieId, string metadataKey);
  event LoreCleared(uint256 zombieId);

  constructor(address _zombiezAddress, address _fleshAddress, address _stakingAddress, address _signVerifier) {
    zombiezAddress = _zombiezAddress;
    fleshAddress = _fleshAddress;
    stakingAddress = _stakingAddress;
    signVerifier = _signVerifier;
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
  function payFleshCost(uint256 fleshCost) internal {
    IERC20 fleshContract = IERC20(fleshAddress);

    // Validate FLESH is approved to be transferred
    uint256 allowance = fleshContract.allowance(msg.sender, address(this));
    require(fleshCost <= allowance, "insufficient approved amount");

    // Transfer cost
    fleshContract.transferFrom(msg.sender, address(this), fleshCost);
  }

  // Generate hash to prove cost calculation for metadata changes
  function getSigningHash(
    uint256 zombieId,
    uint256 fleshCost,
    string memory metadataKey
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(zombieId, fleshCost, metadataKey));
  }

  // Validate cost calculation for metadata changes
  function verifySignature(
    uint256 zombieId,
    uint256 fleshCost,
    string calldata metadataKey,
    bytes calldata sig
  ) internal view {
    bytes32 message = getSigningHash(zombieId, fleshCost, metadataKey).toEthSignedMessageHash();
    require(ECDSA.recover(message, sig) == signVerifier, "verification failure");
  }

  // Function to rewrite lore
  function setMetadataKey(
    uint256 zombieId,
    uint256 fleshCost,
    string calldata metadataKey,
    bytes calldata sig
  ) external isZombieOwner(zombieId) whenNotPaused nonReentrant {
    verifySignature(zombieId, fleshCost, metadataKey, sig);
    payFleshCost(fleshCost);
    metadataKeyMap[zombieId] = metadataKey;
    emit LoreUpdated(zombieId, metadataKey);
  }

  // Return the metadata back to its original state (0 = default)
  function resetMetadata(uint256 zombieId) external isZombieOwner(zombieId) whenNotPaused nonReentrant {
    payFleshCost(resetCost);
    delete metadataKeyMap[zombieId];
    emit LoreCleared(zombieId);
  }

  // Get the current key for token (used by the API)
  function getMetadataKey(uint256 zombieId) external view returns(string memory) {
    string memory metadataKey = metadataKeyMap[zombieId];
    if (bytes(metadataKey).length == 0) {
      return "default"; // return for empty values
    } else {
      return metadataKey;
    }
  }

  // (Owner) Withdraw $FLESH to address
  function withdrawFlesh() external onlyOwner {
    uint256 balance = IERC20(fleshAddress).balanceOf(address(this));
    IERC20(fleshAddress).transfer(msg.sender, balance);
  }

  // Allow owners to change metadata if compelled
  function overrideMetadata(uint256 zombieId) external onlyOwner {
    delete metadataKeyMap[zombieId];
    emit LoreCleared(zombieId);
  }

  // Sets a new signature verifier
  function setSignVerifier(address verifier) external onlyOwner {
    signVerifier = verifier;
  }

  // Update reset cost
  function setResetCost(uint256 _resetCost) external onlyOwner {
    resetCost = _resetCost;
  }

  // Accessor methods for pausing
  function pause() external onlyOwner { _pause(); }
  function unpause() external onlyOwner { _unpause(); }
}
