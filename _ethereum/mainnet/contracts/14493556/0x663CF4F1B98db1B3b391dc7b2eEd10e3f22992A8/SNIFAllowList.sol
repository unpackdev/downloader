// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./SNIF.sol";

/// @title SNIF Allow List
/// @author @KfishNFT
/// @notice Helper contract used for minting SNIF
/// @dev This address must have MINTER_ROLE role in SNIF
contract SNIFAllowList is Ownable {
    /// @notice Merkle Root used to verify if an address is part of the allow list
    bytes32 public merkleRoot;
    /// @notice Used to keep track of addresses that have minted
    mapping(address => bool) public minted;
    /// @notice SNIF contract reference
    SNIF public snif;
    /// @notice Toggleable flag for mint state
    bool public isMintActive;

    /// @notice Contract constructor
    /// @dev The merkle root can be added later if required
    /// @param snif_ address of the SNIF contract
    /// @param merkleRoot_ used to verify the allow list
    constructor(SNIF snif_, bytes32 merkleRoot_) {
        snif = snif_;
        merkleRoot = merkleRoot_;
    }

    /// @notice Function that sets minting active or inactive
    /// @dev only callable from the contract owner
    function toggleMintActive() external onlyOwner {
        isMintActive = !isMintActive;
    }

    /// @notice Sets the SNIF contract address
    /// @dev only callable from the contract owner
    function setSnif(SNIF snif_) external onlyOwner {
        snif = snif_;
    }

    /// @notice Sets the merkle root for allow list verification
    /// @dev only callable from the contract owner
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /// @notice Mint function callable by anyone
    /// @dev requires a valid merkleRoot to function
    /// @param _merkleProof the proof sent by an allow-listed user
    function mint(bytes32[] calldata _merkleProof) public {
        require(isMintActive, "Minting is not active yet");
        require(!minted[msg.sender], "Already minted");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "not in allowlist");

        minted[msg.sender] = true;
        snif.mintAllowList(address(msg.sender));
    }
}
