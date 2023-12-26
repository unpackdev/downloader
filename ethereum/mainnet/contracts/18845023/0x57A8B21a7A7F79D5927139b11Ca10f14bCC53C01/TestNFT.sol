// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";

contract TestNFT is ERC721URIStorage {
    string private zuzaluTokenURI;
    uint256 public totalSupply;
    address public lisaSigner;
    mapping(bytes32 => bool) private minted;

    constructor(
        address lisaSigner_,
        string memory tokenURI_,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        lisaSigner = lisaSigner_;
        zuzaluTokenURI = tokenURI_;
    }

    function mint(string memory pcd, bytes memory lisaSignature) public {
        bytes32 messageHash = getMessageHash(pcd);
        require(!hasMinted(messageHash), "TestNFT: Already minted");
        require(
            recoverSigner(
                getEthSignedMessageHash(messageHash),
                lisaSignature
            ) == lisaSigner,
            "TestNFT: Incorrect signature"
        );
        totalSupply = totalSupply + 1;
        uint256 tokenId = totalSupply;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, zuzaluTokenURI);
        minted[messageHash] = true;
    }

    function hasMinted(bytes32 messageHash) public view returns (bool) {
        return minted[messageHash];
    }

    /**
     * @dev Gets the Ethereum signed message hash of the given hash
     * @param messageHash The hash to sign
     * @return ethSignedMessageHash The Ethereum signed message hash
     */
    function getEthSignedMessageHash(
        bytes32 messageHash
    ) internal pure returns (bytes32 ethSignedMessageHash) {
        /*
         * Signature is produced by signing a keccak256 hash with the following format:
         * "\x19Ethereum Signed Message\n" + len(msg) + msg
         */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    /**
     * @dev Gets a hash of the given message
     * @param message The message to hash
     * @return messageHash The hash of the message
     */
    function getMessageHash(
        string memory message
    ) internal pure returns (bytes32 messageHash) {
        return keccak256(abi.encodePacked(message));
    }

    /**
     * @dev Recovers the signer address from the signature
     * @param ethSignedMessageHash The Ethereum signed message hash
     * @param signature The signature
     * @return signer The address of the signer
     */
    function recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Splits the signature into r, s and v components
     * @param signature The signature to split
     * @return r The r component of the signature
     * @return s The s component of the signature
     * @return v The v component of the signature
     */
    function splitSignature(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // EIP-155: https://eips.ethereum.org/EIPS/eip-155
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid signature 'v' value");
    }
}
