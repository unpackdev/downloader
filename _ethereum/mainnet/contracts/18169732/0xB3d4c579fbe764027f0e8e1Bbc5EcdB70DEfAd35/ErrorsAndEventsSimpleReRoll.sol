// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ErrorsAndEventsSimpleReRoll {
  error BurnWindowNotStarted();
  error BurnWindowEnded();
  error NotOldCoolPetOwnerNorApproved(address account, uint256 oldPetId);
  error InvalidMerkleProof();
  error OnlyEOA();
  error OnlyOwnerOf(uint256 tokenId);
  error OutsideTimestampWindow();
  error IncorrectFundsSent(uint256 expected, uint256 actual);
  error InvalidArrayLength();
  error InvalidBurnWindow();
  error InvalidGemArrays();
  error InvalidNonce(uint256 expected, uint256 actual);
  error InvalidSignature();
  error PetSelectionOutOfRange(uint256 petType, uint256 maxSelectablePetType);
  error SignatureAlreadyUsed();

  event BurnWindowSet(uint256 burnWindowStart, uint256 burnWindowEnd);
  event Combined(
    address indexed account,
    uint256 firstPetId,
    uint256 secondPetId,
    uint256 indexed mintedId,
    uint256[] gemTokenIds,
    uint256 petSelection
  );
  event MaxSlotsSet(uint256 maxSlots);
  event MaxSelectablePetTypeSet(uint256 maxSelectablePetType);
  event MerkleRootSet(bytes32 merkleRoot);
  event NewCoolPetsAddressSet(address newCoolPets);
  event OldCoolPetsAddressSet(address oldCoolPets);
  event ReRolled(address indexed account, uint256 indexed tokenId, bool reRollForm);
  event ReRollCostSet(uint256 rerollCost);
  event SelectPetCostSet(uint256 selectPetCost);
  event SystemAddressSet(address systemAddress);
  event TimestampWindowSet(uint256 timestampWindow);
  event WithdrawAddressSet(address withdrawAddress);
  event Withdrawn(address indexed to, uint256 amount);
}
