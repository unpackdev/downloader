// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ECDSA.sol";
import "./SignatureChecker.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./DeepSkyNetwork.sol";

contract MessageMinter is Pausable, Ownable {
    address public trustedSigner;
    DeepSkyNetwork public collection;
    mapping(address => mapping(uint256 => bool)) public hasClaimed;

    constructor(address _collection, address _trustedSigner) {
        collection = DeepSkyNetwork(_collection);
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

    function claim(uint256 tokenId, address receiver, bytes memory signature) public whenNotPaused {
        require(hasClaimed[receiver][tokenId] == false, "AlreadyClaimed");

        bytes32 messageHash = keccak256(abi.encodePacked(address(this), receiver, tokenId));
        bytes32 ethMessageHash = ECDSA.toEthSignedMessageHash(messageHash);

        require(SignatureChecker.isValidSignatureNow(trustedSigner, ethMessageHash, signature), "InvalidSignature");

        hasClaimed[receiver][tokenId] = true;
        collection.mint(receiver, tokenId, 1, "");
    }
}
