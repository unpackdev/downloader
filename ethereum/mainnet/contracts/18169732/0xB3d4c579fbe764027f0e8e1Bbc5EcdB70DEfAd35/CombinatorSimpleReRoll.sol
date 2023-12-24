// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./ICoolERC721A.sol";
import "./ErrorsAndEventsSimpleReRoll.sol";

//
//
//
//                                                                                                  .@@@%#@&&,(#.
//                                                                                                @@@@@@@@@@@@@@@@&%
//                                                                                               @@@@@@@@@@@@@@@/,@@(
//               &@@@%                                                                        /@@@&@@@@@@@@@@#//
//             @@@@@@@@                        /%@@@&@@@,                                   @@@@@@@@@@@@@@@@@@@@@#
//     &@@&@@@&@@@&@@@@..                  &@@@@@@&@@@@@@@&@@@@(                          @@@@@@&         (&@@@&
//     @@@@@@@@@@@@@@@@@@@@@@@@          ,@@@@@@@@@@@@@@@@@@@@@@@@,                     (@@@@&*   @@@&@/         &@@@@.
//      ,@@@@@@@@@@@@@@@@@@@@&          &@@@@@@@@@@@@@@@@@@@@@@@@@&@@@(                *@@@@@    ,&@@@@@@@@@@@@@@@@@@@&
//      &@@@@@@@@@@@@@@@@@%          &@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@              @@@@&      @@@@@@@@@@@@@@@@@@@&.
//   #@@@@@@@@@@@@&@@@@@@%         ,&@@@@@@@@@@@@@&@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@*    @@@@&     %&@@@@@@@@@@@@@@@&@@@@#
//  @@@@@@@@@@@@@@@@@@@@@@@       ,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@    &@@@@    &@@@@@@@@@@@@@@@@@@@@@@@(
// .&@@@@@@@@@@@@@@@@@@@@@@*      &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@&     .@@@@*   *@&@@@@@@@@@@@@@@@@@@@@@
//  &@@@@@@@@@@@@@@@@@@@@@@       &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@&        @@@@(   *&@@@@@@@@@@@@@@@@@@@&
//    &@@@&@@@&@@@&@@@&@&         .&@@&@@@&@@@&@@@&@@@&@@@&@@@&@@@&@@@&@@@&@@@&@&.        /&@@&#   (@@&@@@&@@@&@@@&@%
//     *@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@          .@@@@@@@@@@@@@@@@@@@@@@@&/
//   &@@@@@@@@@@@@@@@@@@@#          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@&              %@&@@@@@@@@@@@@@@@@@@@@
//    /@@@@@@@@@@@@@@@@@@/          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@/  #@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@
//   #@@@@@@@@@@@@&@@@@@@@&     (@&@@@@@@@@@,  .*%@@@&&&&&@@@@@@@@&@    *@@@@@@@@@&@         *@%* @@%&@@@@(.  %@@@&%@@
//      ,@@@(@@@@@/#@@@          ./@&&&&&&@%            &@@@@@@@@@&@@                               %@@@@&.   ,@@@@@@
//                                                        ,*.#&&%.,.
//
//

/// @title CombinatorSimpleReRoll
/// @author Adam Goodman
/// @notice This contract allows the burning of Cool Pets to upgrade them, and simplified re-rolling of traits
contract CombinatorSimpleReRoll is Ownable, Pausable, ErrorsAndEventsSimpleReRoll {
  using ECDSA for bytes32;

  IERC721 public _oldCoolPets;
  ICoolERC721A public _newCoolPets;

  uint256 public _burnWindowStart;
  uint256 public _burnWindowEnd;

  uint256 public _maxSlots = 3;
  uint256 public _selectPetCost = 0.02 ether;
  uint256 public _reRollCost = 0.02 ether;
  uint256 public _maxSelectablePetType = 3;
  uint256 public _timestampWindow = 180;

  bytes32 public _merkleRoot;

  /// @dev Have to send old pets to 0x000...01 as transfer to 0x0 reverts, and old pets does not expose a burn function
  address public _nullAddress = address(1);

  /// @dev address for message signature verification
  address public _systemAddress;

  /// @dev address for withdrawing funds
  address public _withdrawAddress;

  /// @dev Hold nonces for combining to allow for tracking gem inventory off-chain
  mapping(address => uint256) public _currentNonce;

  /// @dev Hold used signatures for re-rolling
  mapping(bytes => bool) public _usedSignatures;

  // Mapping to only allow a merkle proof array to be used once.
  // Merkle proofs are not guaranteed to be unique to a specific Merkle root. So store them by root.
  mapping(bytes32 => mapping(bytes32 => bool)) public _usedMerkleProofs;

  constructor(
    address oldCoolPets,
    address newCoolPets,
    address systemAddress,
    address withdrawAddress,
    uint64 burnWindowStart,
    uint64 burnWindowEnd
  ) {
    _oldCoolPets = IERC721(oldCoolPets);
    _newCoolPets = ICoolERC721A(newCoolPets);

    _systemAddress = systemAddress;
    _withdrawAddress = withdrawAddress;

    setBurnWindow(burnWindowStart, burnWindowEnd);

    _pause();
  }

  /// @notice Modifier to check if the burn window is open, otherwise revert
  modifier withinBurnWindow() {
    if (block.timestamp < _burnWindowStart) {
      revert BurnWindowNotStarted();
    }

    if (block.timestamp > _burnWindowEnd) {
      revert BurnWindowEnded();
    }
    _;
  }

  /// @notice Checks the input nonce matches the users nonce, and increments the nonce
  modifier validateNonce(address account, uint256 nonce) {
    if (nonce != _currentNonce[account]) {
      revert InvalidNonce(_currentNonce[account], nonce);
    }

    _currentNonce[account]++;

    _;
  }

  /// @notice Burns given old Cool Pets and mints upgraded Cool Pets
  /// @param firstPetId The first old Cool Pet to burn
  /// @param secondPetId The second old Cool Pet to burn
  /// @param gemTokenIds The gem token ids to use in each slot for the new Cool Pet - in order of slot
  /// @param signature The signature to validate the sender, nonce, gemIds and gemTokenIds
  /// @param nonce The nonce for the sender - must be greater than the last nonce used, stops signature replay, starts at 0
  /// @param petSelection The pet type to mint - 0 for random
  function combine(
    uint256 firstPetId,
    uint256 secondPetId,
    uint256[] calldata gemTokenIds,
    bytes calldata signature,
    uint256 nonce,
    uint256 petSelection,
    uint256 timestamp
  ) external payable whenNotPaused withinBurnWindow validateNonce(msg.sender, nonce) {
    if (msg.sender != tx.origin) revert OnlyEOA();
    if (gemTokenIds.length != _maxSlots) revert InvalidGemArrays();
    if (timestamp < block.timestamp - _timestampWindow || timestamp > block.timestamp + 60)
      revert OutsideTimestampWindow();

    if (
      !_isValidSignature(
        keccak256(
          abi.encodePacked(msg.sender, nonce, gemTokenIds, petSelection, timestamp, address(this))
        ),
        signature
      )
    ) revert InvalidSignature();

    _handlePetSelection(petSelection);
    _handleOldPetBurning(firstPetId, secondPetId);

    uint256 mintedId = _newCoolPets.nextTokenId();

    _newCoolPets.mint(msg.sender, 1);

    emit Combined(msg.sender, firstPetId, secondPetId, mintedId, gemTokenIds, petSelection);
  }

  /// @notice re-roll a pets traits
  /// @param tokenId The token id of the pet to re-roll
  /// @param signature The signature to validate the sender, tokenId and timestamp
  /// @param timestamp The timestamp of the re-roll - must be within the timestamp window
  function reRoll(
    uint256 tokenId,
    bytes calldata signature,
    uint256 timestamp,
    bool reRollForm,
    bytes32[] calldata merkleProof
  ) external payable whenNotPaused {
    if (msg.sender != tx.origin) revert OnlyEOA();
    if (_newCoolPets.ownerOf(tokenId) != msg.sender) revert OnlyOwnerOf(tokenId);
    if (timestamp < block.timestamp - _timestampWindow || timestamp > block.timestamp + 60)
      revert OutsideTimestampWindow();

    if (
      !_isValidSignature(
        keccak256(abi.encodePacked(msg.sender, tokenId, timestamp, reRollForm, address(this))),
        signature
      )
    ) revert InvalidSignature();

    if (_usedSignatures[signature]) revert SignatureAlreadyUsed();
    _usedSignatures[signature] = true;

    _handleReRollCost(merkleProof);

    emit ReRolled(msg.sender, tokenId, reRollForm);
  }

  /// @notice Get the current nonce for an account
  function getNonce(address account) external view returns (uint256) {
    return _currentNonce[account];
  }

  /// @notice Get nonces for a list of accounts
  function getNonceBatch(address[] memory accounts) external view returns (uint256[] memory) {
    uint256[] memory nonces = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; i++) {
      nonces[i] = _currentNonce[accounts[i]];
    }

    return nonces;
  }

  /// @notice Pauses the contract - stopping minting via the public mint function
  /// @dev Only the owner can call this function
  ///      Emit handled by {OpenZeppelin Pausable}
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpauses the contract - allowing minting via the public mint function
  /// @dev Only the owner can call this function
  ///      Emit handled by {OpenZeppelin Pausable}
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice Sets the max slots for an input gem array
  /// @dev Only the owner can call this function
  /// @param maxSlots The max slots for an input gem array
  function setMaxSlots(uint256 maxSlots) external onlyOwner {
    _maxSlots = maxSlots;

    emit MaxSlotsSet(maxSlots);
  }

  /// @notice Sets the system address for signature verification
  /// @dev Only the owner can call this function
  /// @param systemAddress The address of the system
  function setSystemAddress(address systemAddress) external onlyOwner {
    _systemAddress = systemAddress;

    emit SystemAddressSet(systemAddress);
  }

  /// @notice Sets the withdraw address for the contract
  /// @dev Only the owner can call this function
  /// @param withdrawAddress The address to withdraw to
  function setWithdrawAddress(address withdrawAddress) external onlyOwner {
    _withdrawAddress = withdrawAddress;

    emit WithdrawAddressSet(withdrawAddress);
  }

  /// @notice Sets the cost for selecting a specific pet type
  /// @dev Only the owner can call this function
  /// @param selectPetCost The cost for selecting a specific pet type
  function setSelectPetCost(uint256 selectPetCost) external onlyOwner {
    _selectPetCost = selectPetCost;

    emit SelectPetCostSet(selectPetCost);
  }

  /// @notice Sets the cost for re-rolling a pet
  /// @dev Only the owner can call this function
  /// @param reRollCost The cost for re-rolling a pet
  function setReRollCost(uint256 reRollCost) external onlyOwner {
    _reRollCost = reRollCost;

    emit ReRollCostSet(reRollCost);
  }

  /// @notice Sets the maximum value for a pet selection
  /// @dev Only the owner can call this function
  /// @param maxSelectablePetType The maximum value for a pet selection
  function setMaxSelectablePetType(uint256 maxSelectablePetType) external onlyOwner {
    _maxSelectablePetType = maxSelectablePetType;

    emit MaxSelectablePetTypeSet(maxSelectablePetType);
  }

  /// @notice Sets the address of the old Cool Pets contract
  /// @dev Only the owner can call this function
  /// @param oldCoolPets The address of the old Cool Pets contract
  function setOldCoolPetsAddress(address oldCoolPets) external onlyOwner {
    _oldCoolPets = IERC721(oldCoolPets);

    emit OldCoolPetsAddressSet(oldCoolPets);
  }

  /// @notice Sets the address of the new Cool Pets contract
  /// @dev Only the owner can call this function
  /// @param newCoolPets The address of the new Cool Pets contract
  function setNewCoolPetsAddress(address newCoolPets) external onlyOwner {
    _newCoolPets = ICoolERC721A(newCoolPets);

    emit NewCoolPetsAddressSet(newCoolPets);
  }

  /// @notice Sets the timestamp window, in seconds
  /// @dev Only the owner can call this function, used for signature verification
  /// @param timestampWindow The timestamp window, in seconds
  function setTimestampWindow(uint256 timestampWindow) external onlyOwner {
    _timestampWindow = timestampWindow;

    emit TimestampWindowSet(timestampWindow);
  }

  /// @notice Check if a merkle proof is valid for a user and if it has been used
  /// @param account The address to check
  /// @param merkleProof The merkle proof to check
  /// @return Whether the merkle proof is valid and has not been used
  function isValidMerkleProofAndUnused(
    address account,
    bytes32[] calldata merkleProof
  ) external view returns (bool) {
    if (_merkleRoot == bytes32(0)) {
      return false;
    }

    if (!isValidMerkleProof(account, merkleProof)) {
      return false;
    }

    bytes32 node = keccak256(abi.encodePacked(account));
    return !_usedMerkleProofs[_merkleRoot][node];
  }

  /// @notice Sets the burn window, start and end times are in seconds since unix epoch
  /// @dev Only the owner can call this function
  /// @param burnWindowStart The start time of the burn window
  /// @param burnWindowEnd The end time of the burn window
  function setBurnWindow(uint256 burnWindowStart, uint256 burnWindowEnd) public onlyOwner {
    if (burnWindowEnd < burnWindowStart) {
      revert InvalidBurnWindow();
    }

    _burnWindowStart = burnWindowStart;
    _burnWindowEnd = burnWindowEnd;

    emit BurnWindowSet(burnWindowStart, burnWindowEnd);
  }

  /// @notice Sets the merkle root for the allowlist
  /// @dev Only the owner can call this function, setting the merkle root does not change
  ///      whether the allowlist is enabled or not
  /// @param merkleRoot The new merkle root
  function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
    _merkleRoot = merkleRoot;

    emit MerkleRootSet(merkleRoot);
  }

  /// @notice Checks if a given address is on the merkle tree allowlist
  /// @dev Merkle trees can be generated using https://github.com/OpenZeppelin/merkle-tree
  /// @param account The address to check
  /// @param merkleProof The merkle proof to check
  /// @return Whether the address is on the allowlist or not
  function isValidMerkleProof(
    address account,
    bytes32[] calldata merkleProof
  ) public view virtual returns (bool) {
    return
      MerkleProof.verifyCalldata(
        merkleProof,
        _merkleRoot,
        keccak256(bytes.concat(keccak256(abi.encode(account))))
      );
  }

  /// @notice Handles the cost of re-rolling a pet
  /// @dev Reverts if the incorrect amount of funds are sent, gives a discount for re-rolling all traits
  function _handleReRollCost(bytes32[] calldata merkleProof) internal {
    if (merkleProof.length > 0 && _merkleRoot != bytes32(0)) {
      if (msg.value != 0) revert IncorrectFundsSent(0, msg.value);
      if (!isValidMerkleProof(msg.sender, merkleProof)) revert InvalidMerkleProof();

      // bytes32 unique identifier for each merkle proof
      bytes32 node = keccak256(abi.encodePacked(msg.sender));
      if (_usedMerkleProofs[_merkleRoot][node]) {
        revert InvalidMerkleProof();
      }
      _usedMerkleProofs[_merkleRoot][node] = true;
    } else {
      if (msg.value != _reRollCost) revert IncorrectFundsSent(_reRollCost, msg.value);

      payable(_withdrawAddress).transfer(_reRollCost);
    }
  }

  /// @notice Handles the ownership (or approval) checks and burning of the old pets
  /// @param firstPetId The first old Cool Pet to burn
  /// @param secondPetId The second old Cool Pet to burn
  function _handleOldPetBurning(uint256 firstPetId, uint256 secondPetId) internal {
    // Check the sender is the owner or approved for each old pet
    // then burn the old pets
    _oldCoolPets.transferFrom(_getOwnerIfApproved(firstPetId), _nullAddress, firstPetId);
    _oldCoolPets.transferFrom(_getOwnerIfApproved(secondPetId), _nullAddress, secondPetId);
  }

  /// @notice handles validating the selected pet type and sending on the funds
  /// @dev If the pet selection is 0 then no pet was selected, so no funds should be sent
  /// @param petSelection The selected pet type
  function _handlePetSelection(uint256 petSelection) internal {
    if (petSelection > _maxSelectablePetType) {
      revert PetSelectionOutOfRange(petSelection, _maxSelectablePetType);
    }

    if (petSelection > 0) {
      if (msg.value != _selectPetCost) {
        revert IncorrectFundsSent(_selectPetCost, msg.value);
      }

      payable(_withdrawAddress).transfer(msg.value);
    } else {
      if (msg.value > 0) {
        revert IncorrectFundsSent(0, msg.value);
      }
    }
  }

  /// @notice Verify hashed data
  /// @param hash - Hashed data bundle
  /// @param signature - Signature to check hash against
  /// @return bool - Is verified or not
  function _isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == _systemAddress;
  }

  /// @notice Checks if a given Fracture is owned by or approved for the sender
  /// @dev This can be used to stop users from being able to burn Fractures someone else owns without their permission
  /// @param tokenId The Fracture to check
  /// @return The owner of the token
  function _getOwnerIfApproved(uint256 tokenId) internal view returns (address) {
    address owner = _oldCoolPets.ownerOf(tokenId);

    if (owner == msg.sender) {
      return owner;
    }

    if (_oldCoolPets.isApprovedForAll(owner, msg.sender)) {
      return owner;
    }

    if (_oldCoolPets.getApproved(tokenId) == msg.sender) {
      return owner;
    }

    revert NotOldCoolPetOwnerNorApproved(msg.sender, tokenId);
  }
}
