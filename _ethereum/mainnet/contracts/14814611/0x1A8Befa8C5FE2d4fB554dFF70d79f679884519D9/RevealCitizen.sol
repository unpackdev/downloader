// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./CitizenERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

import "./console.sol";

contract RevealCitizen is Ownable {

    using ECDSA for bytes32;

    CitizenERC721 public _revealERC721;

    // The reveal oracle verifies signatures offchain.
    address public _revealOracleAddr;

    // The reveal CID is an IPFS document containing a distribution of the NFTs yet to be revealed.
    string public _revealCid;

    constructor (CitizenERC721 citizenERC721) public {
        _revealERC721 = citizenERC721;
    }

    event RevealCid(
        string _revealCid
    );

    event RevealOracleAddress(
        address _revealOracleAddr
    );

    // Reveal indicates that the Passport has been associated and can be used to verify oracle.
    event Reveal(
        uint256 tokenId,
        uint256 primaryPublicKeyX,
        uint256 primaryPublicKeyY,
        uint256 r,
        uint256 s, 
        uint256 blockNumber
    );

    // IPFS CID containing the attributes to be distributed.
    function updateRevealCid(string memory newCid) public onlyOwner {
        _revealCid = newCid;
        emit RevealCid(_revealCid);
    }

    // Address of the oracle signer.
    function updateRevealAddr(address newAddr) public onlyOwner {
        _revealOracleAddr = newAddr;
        emit RevealOracleAddress(_revealOracleAddr);
    }

    // Verify the oracleSignature.
    function _verify(bytes32 data, bytes memory signature, address account) internal pure returns (bool) {
        return data
            .toEthSignedMessageHash()
            .recover(signature) == account;
    }

    // Set the device and reveal NFT after an oracle has verfied the P256 signature from the device.
    function revealOracle(uint256 tokenId, 
                          uint[2] memory rs, 
                          uint256 primaryPublicKeyX,
                          uint256 primaryPublicKeyY, 
                          uint256 blockNumber,
                          bytes32 merkleRoot, 
                          bytes memory oracleSignature) external {
        
        address from = msg.sender;

        // The reveal CID must be set for minting to open.
        require(bytes(_revealCid).length > 0, "Cannot mint yet, token attributes not set.");

        // Only the holder of the token can execute this contract.
        require(_revealERC721.ownerOf(tokenId) == from, "Only token holder can reveal.");

        // Lookup tokenId, require that the device isn't set on the token yet.
        require(_revealERC721.deviceId(tokenId) == 0, "Device already set for this token.");

        // SHA256 hash of the device's primary public key.
        bytes32 publicKeyHash = sha256(abi.encodePacked(primaryPublicKeyX, primaryPublicKeyY));
        // console.logBytes32(publicKeyHash);

        // Hash of the Passport holder's address, the blockhash and the primaryPublicKeyHash; this is what the oracle signed.
        bytes32 oracleHash = sha256(abi.encodePacked(publicKeyHash, sha256(abi.encodePacked(rs)), sha256(abi.encodePacked(from, blockhash(blockNumber)))));
        // console.logBytes32(oracleHash);

        // Signature from the revealOracle indicating that verification of the P256 signature completed successfully.
        require(_verify(oracleHash, oracleSignature, _revealOracleAddr), "Verify failed.");

        // setDevice in erc721.
        _revealERC721.setDevice(tokenId, publicKeyHash, merkleRoot);

        // Note: the registry address is implicit against what is in CitizenERC721. Reveal information should
        // allow for honesty check of oracle. rs will be hashed with subsequent block to reveal.
        emit Reveal(tokenId, primaryPublicKeyX, primaryPublicKeyY, rs[0], rs[1], blockNumber);
        
    }

}