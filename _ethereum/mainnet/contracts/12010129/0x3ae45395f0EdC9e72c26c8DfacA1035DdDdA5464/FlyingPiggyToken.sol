// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./MerkleProof.sol";

contract FlyingPiggyToken is ERC721, Ownable {
    // Claim is paused
    bool private _claimPaused;

    // Airdrops merkle tree root
    bytes32 private _merkleRoot;

    // Mapping from address to claimed
    mapping(address => bool) private claimed;

    // Aauto increment tokenId
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event MerkleRoot(bytes32 merkleRoot);
    event ClaimPaused(bool baseURI);
    event BaseURI(string baseURI);
    event Claim(address recipient, uint256 tokenId);

    /**
     * @dev Initializes the contract by setting a `name`, a `symbol`, a `merkleRoot` and a `baseURI` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        bytes32 merkleRoot_,
        string memory baseURI_
    ) public ERC721(name_, symbol_) {
        _merkleRoot = merkleRoot_;
        _setBaseURI(baseURI_);
    }

    /** --- owner config start --- */

    /**
     * @dev Paused claim or start claim
     * Emits a {ClaimPaused} event.
     */
    function setClaimPaused(bool state) public onlyOwner {
        _claimPaused = state;
        emit ClaimPaused(state);
    }

    /**
     * @dev Setting a merkle tree root
     * Emits a {MerkleRoot} event.
     */
    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        _merkleRoot = merkleRoot_;
        emit MerkleRoot(_merkleRoot);
    }

    /**
     * @dev Setting a baseURI for nft
     * Emits a {BaseURI} event.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
        emit BaseURI(baseURI_);
    }

    /** --- owner config end --- */

    /**
     * @dev Returns current claim state
     */
    function claimPaused() public view returns (bool) {
        return _claimPaused;
    }

    /**
     * @dev Returns current merkle tree root
     */
    function merkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }

    /**
     * @dev Claim for msg sender
     * Emits a {Claim} event.
     */
    function claim(bytes32[] memory proof_) public {
        _claim(proof_, msg.sender);
    }

    /**
     * @dev Claim for recipient
     * Emits a {Claim} event.
     */
    function claimBehalf(bytes32[] memory proof_, address recipient) public {
        _claim(proof_, recipient);
    }

    /**
     * @dev Returns whether the recipient has claimed
     */
    function isClaimed(address recipient) public view returns (bool) {
        return claimed[recipient];
    }

    /**
     * @dev Returns whether the recipient can claim
     */
    function verifyProof(bytes32[] memory proof_, address recipient) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(recipient));
        return MerkleProof.verify(proof_, _merkleRoot, leaf);
    }

    /**
     * @dev Claim for recipient
     * Emits a {Claim} event.
     */
    function _claim(bytes32[] memory proof_, address recipient) internal {
        require(!_claimPaused, "Claim is paused.");
        // Make sure this reward has not already been claimed (and claim it)
        require(!claimed[recipient], "You have already claimed your rewards.");

        require(verifyProof(proof_, recipient), "The proof could not be verified.");

        claimed[recipient] = true;

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(recipient, newTokenId);

        emit Claim(recipient, newTokenId);
    }
}
