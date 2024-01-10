// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ERC721ATradable.sol";

/**
 * @title Oni Mansion Contract
 * @author onisquad.gg
 * @notice This contract handles minting for Oni Mansions.
 */
contract OniMansion is ERC721ATradable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public mintPrice = 0.12 ether;
    uint256 public maxSupply = 10000;

    mapping (address => uint256) public totalMintsPerAddress;

    // // Used to validate authorized mint addresses
    address private signerAddress = 0xB79C8d5fD2AC5F77887769a211cE09aE9534f32E;
    bool setSupply;

    /**
    * @notice Contract Constructor
    */
    constructor(
      string memory baseTokenURI_
    ) ERC721ATradable("Oni Mansion NFT", "OM", baseTokenURI_) {
        includedProxies.push(0xa5409ec958C83C3f309868babACA7c86DCB077c1);
        proxyToApprove[0xa5409ec958C83C3f309868babACA7c86DCB077c1] = true;
        receiverAddress = 0xe136FB79114C5dCf135091Dcba34f302DE8B1687;
    }

    // PUBLIC API

    /**
     * @notice Allow for minting of tokens up to the maximum allowed for a given address.
     * The address of the sender and the number of mints allowed are hashed and signed
     * with a private key and verified here to prove allowlisting status.
     * @param messageHash: message created by the backend that will be verified against the signature.
     * @param signature: message with signature.
     * @param mintNumber: how many NFTs caller wants to mint.
     * @param maximumAllowedMints: maximum number of nfts that can be minted from the caller.
     */
    function mint(
        bytes32 messageHash,
        bytes calldata signature,
        uint256 mintNumber,
        uint256 maximumAllowedMints
    ) public virtual nonReentrant {
        require(
          totalMintsPerAddress[msg.sender] + mintNumber < maximumAllowedMints + 1 ,
          "MintNumber is more than maximumAllowedMints."
        );
        require(hashMessage(msg.sender, maximumAllowedMints) == messageHash, "MESSAGE_INVALID");
        require(verifyAddressSigner(messageHash, signature), "SIGNATURE_VALIDATION_FAILED");
        require(totalSupply() + mintNumber < maxSupply + 1, "Max Supply Reached");

        totalMintsPerAddress[msg.sender] += mintNumber;

        _safeMint(msg.sender, mintNumber);
    }


    /**
     * @notice Similar to mint/4, but also payable.
     */
    function allowListMint(
        bytes32 messageHash,
        bytes calldata signature,
        uint256 mintNumber,
        uint256 maximumAllowedMints
    ) external payable {
        require(msg.value == (mintPrice * mintNumber),"INVALID_PRICE");
        mint(messageHash, signature, mintNumber, maximumAllowedMints);
    }

    // Setters

    /**
    * @notice Update signer address.
    * @param _signerAddress: new signer address value.
    */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        require(_signerAddress != address(0));
        signerAddress = _signerAddress;
    }

    /**
    * @notice Update mint price.
    * @param _newPrice: amount to mint one oni mansion.
    */
    function setMintingPrice(uint256 _newPrice) external onlyOwner() {
      mintPrice = _newPrice;
    }

    /**
    * @notice Update max supply (can only be called once).
    * @param _newSupply: new maximum supply value.
    */
    function setMaxSupply(uint256 _newSupply) external onlyOwner() {
      require(setSupply == false, "The maximum supply was already set.");
      setSupply = true;
      maxSupply = _newSupply;
    }

    // PRIVATE FUNCTIONS
    
    function verifyAddressSigner(bytes32 messageHash, bytes memory signature) private view returns (bool) {
        return signerAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(address sender, uint256 maximumAllowedMints) private pure returns (bytes32) {
        return keccak256(abi.encode(sender, maximumAllowedMints));
    }
}
