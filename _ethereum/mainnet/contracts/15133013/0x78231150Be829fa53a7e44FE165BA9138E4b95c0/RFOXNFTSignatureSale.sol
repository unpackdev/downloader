// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ECDSA.sol";
import "./BaseRFOXNFT.sol";

/**
 * @dev This is the extension contract of the base RFOX NFT.
 * This contract can be used to prevent the spam minting by bot.
 */
contract RFOXNFTSignatureSale is BaseRFOXNFT {
  using ECDSA for bytes32;

  address public authorizedSignerAddress;
  mapping(bytes => bool) usedSignature;

  event AuthorizedSignerAddress(address indexed sender, address oldAddress, address newAddress);

  modifier checkUsedSignature(bytes calldata signature) {
    require(!usedSignature[signature], "Signature has been used");
    _;
  }

  /**
   * @dev Verify hashed data.
   * param hash Hashed data bundle
   * @param signature Signature to check hash against
   * @return bool Is signature valid or not
   */
  function _isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool) {
    require(authorizedSignerAddress != address(0), "Invalid signer addr");
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == authorizedSignerAddress;
  }

  /**
   * @dev Update the authorized signer address.
   *
   * @param signerAddress new authorized signer address.
   */
  function changeAuthorizedSignerAddress(address signerAddress) external onlyOwner {
    require(signerAddress != address(0), "ERR_ZERO_ADDRESS");
    address oldSignerAddress = authorizedSignerAddress;
    authorizedSignerAddress = signerAddress;
    emit AuthorizedSignerAddress(msg.sender, oldSignerAddress, signerAddress);
  }

  /**
   * @dev Public sale which required the signature of the authorized signer.
   *
   * @param tokensNumber How many NFTs for buying this round.
   * @param salt The random number (unique per address) to be used for the signature verification.
   * @param signature The signature of the authorized signer address.
   */
  function buyNFTsPublic(uint256 tokensNumber, uint256 salt, bytes calldata signature) external payable whenNotPaused callerIsUser authorizePublicSale maxPurchasePerTx(tokensNumber) checkUsedSignature(signature) {
    require(_isValidSignature(keccak256(abi.encodePacked(msg.sender,address(this),salt)), signature), "Invalid signature");

    usedSignature[signature] = true;

    _buyNFTs(tokensNumber);
  }
}
