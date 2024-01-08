//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ECDSA.sol";

import "./INiftyForge721.sol";
import "./NFBaseModule.sol";

/// @title EncryptedStoriesModule
/// @author Simon Fremaux (@dievardump)
contract EncryptedStoriesModule is Ownable, NFBaseModule {
    // this is because minting is secured with a Signature
    using ECDSA for bytes32;

    // contract on which this module is made to mint
    address public nftContract;

    // address used to sign the mint URLs
    address public signer;

    // minting fee
    uint256 public mintFee = 0.1 ether;

    /// @notice constructor
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    /// @param nftContract_ contract on which we mint
    /// @param signer_ the address of the signer for minting
    constructor(
        string memory contractURI_,
        address owner_,
        address nftContract_,
        address signer_
    ) NFBaseModule(contractURI_) {
        if (address(0) != nftContract_) {
            nftContract = nftContract_;
        }

        if (address(0) != signer_) {
            signer = signer_;
        }

        if (address(0) != owner_) {
            transferOwnership(owner_);
        }
    }

    /// @notice sets contract uri
    /// @param newURI the new uri
    function setContractURI(string memory newURI) external onlyOwner {
        _setContractURI(newURI);
    }

    /// @notice Setter for nfts contract
    /// @param nftContract_ the contract containing planets
    function setNFTContract(address nftContract_) external onlyOwner {
        nftContract = nftContract_;
    }

    /// @notice Setter for signer allowing mints
    /// @param signer_ the new signer
    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /// @notice Setter for minting fee
    /// @param mintFee_ the new fee to mint
    function setMintFee(uint256 mintFee_) external onlyOwner {
        mintFee = mintFee_;
    }

    /// @dev Owner withdraw balance function
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }

    /// @notice Minting function
    /// @param tokenId the token Id to mint
    /// @param signature the signature for the mint
    function mint(
        uint256 tokenId,
        address to,
        bytes memory signature
    ) external payable {
        // if it's not the owner, verify mintFee and signature
        if (msg.sender != owner()) {
            require(msg.value == mintFee, '!WRONG_VALUE!');
            require(_verifySignature(tokenId, signature), '!WRONG_SIGNATURE!');
        }

        if (to == address(0)) {
            to = msg.sender;
        }

        INiftyForge721(nftContract).mint(
            to,
            '',
            tokenId,
            address(0),
            0,
            address(0)
        );
    }

    /// @notice Helper that creates the message that signer needs to sign to allow a mint
    /// @param tokenId the tokenId
    /// @return the message to signe
    function createMessage(uint256 tokenId) public view returns (bytes32) {
        return keccak256(abi.encode(tokenId, address(this)));
    }

    /// @notice verifies thatsignature correspond to message
    /// @param tokenId the tokenId
    /// @return if signature is right
    function _verifySignature(uint256 tokenId, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 message = createMessage(tokenId).toEthSignedMessageHash();
        return message.recover(signature) == signer;
    }
}
