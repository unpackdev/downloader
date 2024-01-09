// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ECDSA.sol";
import "./SignatureChecker.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./TheLostGlitchesComic.sol";

contract ComicAirdropMinter is Pausable, Ownable {
    address public trustedSigner;
    TheLostGlitchesComic public collection;
    mapping(address => bool) public hasClaimed;

    constructor(address _collection, address _trustedSigner) {
        collection = TheLostGlitchesComic(_collection);
        trustedSigner = _trustedSigner;
    }

    function setTrustedSigner(address _trustedSigner) public onlyOwner {
        trustedSigner = _trustedSigner;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function claimComic(address receiver, bytes memory signature) public whenNotPaused {
        require(hasClaimed[receiver] == false, "AlreadyClaimed");
        require(collection.presaleIsActive(), "TheLostGlitchesComic: Sale is not active");
        bytes32 messageHash = keccak256(abi.encodePacked(address(this), receiver));
        bytes32 ethMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        require(SignatureChecker.isValidSignatureNow(trustedSigner, ethMessageHash, signature), "InvalidSignature");

        hasClaimed[receiver] = true;
        collection.mintAirdrop(receiver);
    }
}
