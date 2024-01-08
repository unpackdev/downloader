pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./UseAccessControl.sol";
import "./PermissionedTokenMetadataRegistry.sol";
import "./MixinSignature.sol";
import "./MixinPausable.sol";
import "./IERC20.sol";

contract SnapshotAffirmationWriter is MixinSignature, MixinPausable, UseAccessControl {

  PermissionedTokenMetadataRegistry public permissionedTokenMetadataRegistry;

  bytes32 public immutable organizerRole;
  bytes32 public immutable historianRole;

  IERC20 public immutable tipToken;

  uint256 public minimumQuorumAffirmations;
  
  uint256 public constant VERSION = 2;

  address payable public historianTipJar;

  mapping(bytes32 => bool) public affirmationHashRegistry;
  mapping(bytes32 => bool) public tipHashRegistry;
  
  constructor(
    address _accessControl,
    address _permissionedTokenMetadataRegistry,
    address payable _historianTipJar,
    address _tipToken,
    bytes32 _organizerRole,
    bytes32 _historianRole
  ) UseAccessControl(_accessControl) {
    permissionedTokenMetadataRegistry = PermissionedTokenMetadataRegistry(_permissionedTokenMetadataRegistry);
    organizerRole = _organizerRole;
    historianRole = _historianRole;
    historianTipJar = _historianTipJar;
    tipToken = IERC20(_tipToken);
  }

	struct Affirmation {
		uint256 salt;
    address signer;
    bytes signature;
	}

	struct Tip {
    uint256 version;
		bytes32 writeHash;
    address tipper;
    uint256 value;
    bytes signature;
	}

	struct Write {
    uint256 tokenId;
    string key;
		string text;
    uint256 salt;
	}

  event Affirmed(
      uint256 indexed tokenId,
      address indexed signer,
      string indexed key,
      bytes32 affirmationHash,
      uint256 salt,
      bytes signature
  );

  event Tipped(
      bytes32 indexed writeHash,
      address indexed tipper,
      uint256 value,
      bytes signature
  );

  function getWriteHash(Write calldata _write) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_write.tokenId, _write.key, _write.text, _write.salt));
}

  function getAffirmationHash(bytes32 _writeHash, Affirmation calldata _affirmation) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_writeHash, _affirmation.signer, _affirmation.salt));
  }

  function getTipHash(Tip calldata _tip) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_tip.version, _tip.writeHash, _tip.tipper, _tip.value));
  }

  function verifyAffirmation(
    bytes32 writeHash, Affirmation calldata _affirmation 
  ) public pure returns (bool) {
    bytes32 signedHash = getAffirmationHash(writeHash, _affirmation);
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_affirmation.signature);
    return isSigned(_affirmation.signer, signedHash, v, r, s);
  }

  function verifyTip(
    Tip calldata _tip 
  ) public pure returns (bool) {
    bytes32 signedHash = getTipHash(_tip);
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_tip.signature);
    return _tip.version == VERSION && isSigned(_tip.tipper, signedHash, v, r, s);
  }

  function updateMinimumQuorumAffirmations(uint256 _minimumQuorumAffirmations) public onlyRole(organizerRole) {
    minimumQuorumAffirmations = _minimumQuorumAffirmations;
  }

  function updateHistorianTipJar(address payable _historianTipJar) public onlyRole(organizerRole) {
    historianTipJar = _historianTipJar;
  }

  function pause() public onlyRole(organizerRole) {
    _pause();
  }

  function unpause() public onlyRole(organizerRole) {
    _unpause();
  } 

  function write(Write calldata _write, Affirmation[] calldata _affirmations, Tip calldata _tip) public whenNotPaused {
    bytes32 writeHash = getWriteHash(_write);

    uint256 numValidAffirmations = 0;
    for (uint256 i = 0; i < _affirmations.length; ++i) {
      Affirmation calldata affirmation = _affirmations[i];
      // once an affirmation is created and used on-chain it can't be used again
      bytes32 affirmationHash = getAffirmationHash(writeHash, affirmation);
      require(affirmationHashRegistry[affirmationHash] == false, "Affirmation has already been received");
      affirmationHashRegistry[affirmationHash] = true;
      require(verifyAffirmation(writeHash, affirmation) == true, "Affirmation doesn't have valid signature");
      _checkRole(historianRole, affirmation.signer);
      numValidAffirmations++;
      emit Affirmed(_write.tokenId, affirmation.signer, _write.key, affirmationHash, affirmation.salt, affirmation.signature ); 
    }

    require(numValidAffirmations >= minimumQuorumAffirmations, "Minimum affirmations not met");
    
    _writeDocument(_write);
    _settleTip(writeHash, _tip);
  }

  function _writeDocument(Write calldata _write) internal {
    string[] memory keys = new string[](1);
    string[] memory texts = new string[](1);
    keys[0] = _write.key;
    texts[0] = _write.text;
    permissionedTokenMetadataRegistry.writeDocuments(_write.tokenId, keys, texts); 
  }

  function settleTip(bytes32 writeHash, Tip calldata _tip) public onlyRole(historianRole) {
    _settleTip(writeHash, _tip);
  }

  function _settleTip(bytes32 writeHash, Tip calldata _tip) internal {
    if (_tip.value != 0) {
      require (writeHash == _tip.writeHash, 'Tip is not for write');
      bytes32 tipHash = getTipHash(_tip);
      require(tipHashRegistry[tipHash] == false, "Tip has already been used");
      tipHashRegistry[tipHash] = true;
      require(verifyTip(_tip) == true, "Tip doesn't have valid signature");
      tipToken.transferFrom(_tip.tipper, historianTipJar, _tip.value);
      emit Tipped(_tip.writeHash, _tip.tipper, _tip.value, _tip.signature);
    }
  }

}