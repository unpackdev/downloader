// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "./IAssetsInteraction.sol";
import "./BAPApesInterface.sol";
import "./Ownable.sol";

/// @title Bulls and Apes Project - God Minting Contract
/// @author BAP Dev Team
/// @notice Handle the minting of God Apes through the BAP gamification
contract GodMinting is Ownable {
  /// @notice Counter of Gods minted
  uint256 public godCounter;

  /// @notice Apes Contract instance
  BAPApesInterface public bapApes;
  /// @notice Assets Interactions contract instance
  IAssetsInteraction public assetsInteractionContract;

  /// @notice Address of the wallet that signs messages
  address public secret;

  /// @notice Boolean to prevent using the same signature twice
  mapping(bytes => bool) public usedSignatures;

  /// @notice God Minted event
  /// @param element: Element of the God Bull minted, 12 Elements in total (0-11)
  /// @param compass: God is Good (0) or Evil (1)
  event GodBullMinted(
    address user,
    uint256 godId,
    uint256 element,
    uint256 compass
  );

  /// @notice Deploys the contract and sets the instances addresses
  /// @param apesAddress: Address of the Apes Contract
  /// @param assetsInteractionAddress: Address of the Teen Bulls contract
  constructor(address apesAddress, address assetsInteractionAddress) {
    bapApes = BAPApesInterface(apesAddress);
    assetsInteractionContract = IAssetsInteraction(assetsInteractionAddress);
  }

  /// @notice Mint a God Bull
  /// @param recipient: Address of the recipient
  /// @param apeId: ID of the Ape to use
  /// @param element: Element of the God Bull minted, 12 Elements in total (0-11)
  /// @param compass: God is Good (0) or Evil (1)
  /// @param signature: Signature to confirm above parameters
  function mintGodApes(
    address recipient,
    uint256 apeId,
    uint256 element,
    uint256 compass,
    bytes memory signature
  ) external {
    require(godCounter < 1000, "mintGodApes: All Gods minted");
    require(!usedSignatures[signature], "mintGodApes: Signature already used");
    require(
      _verifyHashSignature(
        keccak256(abi.encode(recipient, apeId, element, compass, "God Mint")),
        signature
      ),
      "mintGodApes: Invalid signature"
    );

    usedSignatures[signature] = true;
    godCounter++;

    assetsInteractionContract.resurrectApe(apeId, recipient); // Send the Ape to the user
    bapApes.confirmChange(apeId); // burn-mint Ape to transform it into a God Ape

    emit GodBullMinted(recipient, apeId + 10000, element, compass);
  }

  /// @notice Internal function to set a new signer
  /// @param newSigner: Address of the new signer
  /// @dev Only the owner can set a new signer
  function setSigner(address newSigner) external onlyOwner {
    require(newSigner != address(0), "Invalid address");
    secret = newSigner;
  }

  /// @notice Transfer ownership from external contracts owned by this contract
  /// @param _contract Address of the external contract
  /// @param _newOwner New owner
  /// @dev Only contract owner can call this function
  function transferOwnershipExternalContract(
    address _contract,
    address _newOwner
  ) external onlyOwner {
    Ownable(_contract).transferOwnership(_newOwner);
  }

  /// @notice Set new contracts addresses
  /// @param apesAddress: Address of the Apes Contract
  /// @param assetsInteractionAddress: Address of the Teen Bulls contract
  /// @dev Only contract owner can call this function
  function setContractsAddresses(
    address apesAddress,
    address assetsInteractionAddress
  ) external onlyOwner {
    bapApes = BAPApesInterface(apesAddress);
    assetsInteractionContract = IAssetsInteraction(assetsInteractionAddress);
  }

  /// @notice Internal function to check if a signature is valid
  /// @param freshHash: Hash to check
  /// @param signature: Signature to check
  function _verifyHashSignature(
    bytes32 freshHash,
    bytes memory signature
  ) internal view returns (bool) {
    bytes32 hash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
    );

    bytes32 r;
    bytes32 s;
    uint8 v;

    if (signature.length != 65) {
      return false;
    }
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }

    if (v < 27) {
      v += 27;
    }

    address signer = address(0);
    if (v == 27 || v == 28) {
      // solium-disable-next-line arg-overflow
      signer = ecrecover(hash, v, r, s);
    }
    return secret == signer;
  }
}
