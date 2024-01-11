// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Minter.sol";
import "./StringDictionary.sol";
import "./Shrine.sol";

import "./Ownable.sol";
import "./MerkleProof.sol";

/// @title ChainFaces HD - Shrine
/// @author Kane Wallmann (Secret Project Team)
contract ChainFacesHDShrine is Ownable, StringDictionaryInterface, ShrineInterface {

    //
    // Errors
    //

    error AlreadyRevealed();
    error AlreadyClaimed();
    error MinterNotSet();
    error InvalidProof();
    error InvalidSecret();

    //
    // Immutables
    //

    /// @dev The root of the merkle tree
    bytes32 immutable merkleRoot;

    //
    // Public variables
    //

    // @dev Record the number of rounds a dead face survived in the arena
    mapping(uint256 => uint256) public override roundsSurvived;

    /// @dev The secret value
    uint256 public override secret;

    //
    // Private variables
    //

    /// @dev A bitmap of claimed indices
    mapping(uint256 => uint256) private claimedBitMap;

    /// @dev The contract which is called to mint resurrected ChainFaces
    MinterInterface private minter;

    /// @dev A mapping of keys to strings
    mapping(uint256 => string) private dictionary;

    //
    // Constructor
    //

    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
    }

    //
    // Public functions
    //

    /// @dev Performs a resurrection of a ChainFace Arena who died in the arena
    /// @param _index The merkle tree entries index
    /// @param _id The token id to be resurrected
    /// @param _roundsSurvived The number of rounds the dead ChainFace survived in the arena
    /// @param _merkleProof Proof that the given values exist as a leaf node in the merkle tree
    function resurrect(uint256 _index, uint256 _id, uint256 _roundsSurvived, bytes32[] calldata _merkleProof) external {
        // Can't mint after reveal
        if (isRevealed()) {
            revert AlreadyRevealed();
        }

        // Can only mint once minter is set
        if (address(minter) == address(0)) {
            revert MinterNotSet();
        }

        // Ensure not already claimed
        if (isClaimed(_index)) {
            revert AlreadyClaimed();
        }

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(_index, msg.sender, _id, _roundsSurvived));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }

        // Mark it claimed and store the round survived
        _setClaimed(_index);
        roundsSurvived[_id] = _roundsSurvived;

        // Mint
        minter.mint(msg.sender, _id);
    }

    /// @dev Performs a resurrection of multiple ChainFaces who died in the arena
    /// @param _index Array of the merkle tree entries indices
    /// @param _id Array of the token ids to be resurrected
    /// @param _roundsSurvived Array of the number of rounds the dead ChainFaces survived in the arena
    /// @param _merkleProof Array of proofs that the given values exist as a leaf node in the merkle tree
    function resurrectMulti(uint256[] calldata _index, uint256[] calldata _id, uint256[] calldata _roundsSurvived, bytes32[][] calldata _merkleProof) external {
        // Can't mint after reveal
        if (isRevealed()) {
            revert AlreadyRevealed();
        }

        // Can only mint once minter is set
        if (address(minter) == address(0)) {
            revert MinterNotSet();
        }

        // Loop over inputs and mint
        for (uint256 i = 0; i < _index.length; i++) {
            // Ensure not already claimed
            if (isClaimed(_index[i])) {
                revert AlreadyClaimed();
            }

            // Verify the merkle proof
            bytes32 node = keccak256(abi.encodePacked(_index[i], msg.sender, _id[i], _roundsSurvived[i]));
            if (!MerkleProof.verify(_merkleProof[i], merkleRoot, node)) {
                revert InvalidProof();
            }

            // Mark it claimed and store the round survived
            _setClaimed(_index[i]);
            roundsSurvived[_id[i]] = _roundsSurvived[i];

            // Mint
            minter.mint(msg.sender, _id[i]);
        }
    }

    /// @dev Returns whether the given index has been claimed yet
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// @dev Returns whether the secret has been revealed
    function isRevealed() public view returns (bool) {
        return secret != 0;
    }

    /// @dev Returns the string for a given key
    function getString(uint256 _key) external view override returns (string memory) {
        return dictionary[_key];
    }

    //
    // Privileged functions
    //

    /// @dev Sets the contract on which mint is called to resurrect undead faces
    function setMinter(address _minter) external onlyOwner {
        minter = MinterInterface(_minter);
    }

    /// @dev Sets a string for a given key
    function setString(uint256 _key, string memory _string) external override onlyOwner {
        dictionary[_key] = _string;
    }

    /// @dev Reveals the secret
    function reveal(uint256 _secretReveal) external onlyOwner {
        // Can't reveal more than once
        if (isRevealed()) {
            revert AlreadyRevealed();
        }

        // Update the state
        secret = _secretReveal;
    }

    //
    // Private functions
    //

    /// @dev Sets the claimed state of a given index to true
    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
}
