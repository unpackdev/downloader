pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./LibString.sol";
import "./PermissionedTokenMetadataRegistry.sol";
import "./MixinOwnable.sol";
import "./MixinSignature.sol";
import "./MixinPausable.sol";

contract SnapshotAffirmationWriter is Ownable, MixinSignature, MixinPausable {

  PermissionedTokenMetadataRegistry public permissionedTokenMetadataRegistry;

  mapping(address => bool) public permissedAffirmers;

  uint256 public minimumQuorumAffirmations;

  mapping(bytes32 => bool) public affirmationHashRegistry;

  constructor(
    address _permissionedTokenMetadataRegistry
  ) {
    permissionedTokenMetadataRegistry = PermissionedTokenMetadataRegistry(_permissionedTokenMetadataRegistry);
  }

	struct Affirmation {
		uint256 salt;
    address signer;
    bytes signature;
	}

	struct Write {
    uint256 tokenId;
    string key;
		string text;
    uint256 salt;
	}

  event Affirmed(
      bytes32 indexed writeHash,
      bytes32 indexed affirmationHash,
      address indexed signer,
      uint256 salt,
      bytes signature
  );

  function getWriteHash(Write calldata _write) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_write.tokenId, _write.key, _write.text, _write.salt));
  }

  function getAffirmationHash(bytes32 _writeHash, Affirmation calldata _affirmation) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_writeHash, _affirmation.signer, _affirmation.salt));
  }

  function verifyAffirmation(
    bytes32 writeHash, Affirmation calldata _affirmation 
  ) public pure returns (bool) {
    bytes32 signedHash = getAffirmationHash(writeHash, _affirmation);
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_affirmation.signature);
    return isSigned(_affirmation.signer, signedHash, v, r, s);
  }

  function updatePermissedAffirmersStatus(address _affirmer, bool status) public onlyOwner() {
    permissedAffirmers[_affirmer] = status;
  }

  function updateMinimumQuorumAffirmations(uint256 _minimumQuorumAffirmations) public onlyOwner() {
    minimumQuorumAffirmations = _minimumQuorumAffirmations;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  } 

  function write(Write calldata _write, Affirmation[] calldata _affirmations) public whenNotPaused {
    bytes32 writeHash = getWriteHash(_write);

    uint256 numValidAffirmations = 0;
    for (uint256 i = 0; i < _affirmations.length; ++i) {
      Affirmation calldata affirmation = _affirmations[i];
      // once an affirmation is created and used on-chain it can't be used again
      bytes32 affirmationHash = keccak256(abi.encodePacked(writeHash, affirmation.signer));
      require(affirmationHashRegistry[affirmationHash] == false, "Affirmation has already been received");
      affirmationHashRegistry[affirmationHash] = true;
      require(verifyAffirmation(writeHash, affirmation) == true, "Affirmation doesn't have valid signature");
      require(permissedAffirmers[affirmation.signer] == true, "Affirmer is not valid");
      emit Affirmed(writeHash, affirmationHash, affirmation.signer, affirmation.salt, affirmation.signature ); 
      numValidAffirmations++;
    }

    require(numValidAffirmations >= minimumQuorumAffirmations, "Minimum affirmations not met");

    string[] memory keys = new string[](1);
    string[] memory texts = new string[](1);
    keys[0] = _write.key;
    texts[0] = _write.text;
    permissionedTokenMetadataRegistry.writeDocuments(_write.tokenId, keys, texts);
  }

}