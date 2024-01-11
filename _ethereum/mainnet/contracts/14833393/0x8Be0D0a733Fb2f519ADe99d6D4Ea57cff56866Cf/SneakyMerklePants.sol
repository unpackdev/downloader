// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./SneakyGenesis.sol";

/// @title Sneaky Genesis Allow List
/// @author @KfishNFT
/// @notice Helper contract used for minting Sneaky Genesis
/// @dev This address must have MINTER_ROLE role in SneakyGenesis
contract SneakyMerklePants is Ownable {
    /// @notice Merkle Root used to verify if an address is part of the allow list
    bytes32 public merkleRoot;
    /// @notice Used to keep track of addresses that have minted
    mapping(address => bool) public minted;
    /// @notice SneakyGenesis contract reference
    SneakyGenesis public sneakyGenesis;
    /// @notice Toggleable flag for mint state
    bool public isMintActive;

    /// @notice Contract constructor
    /// @dev The merkle root can be added later if required
    /// @param sneakyGenesis_ address of the SneakyGenesis contract
    /// @param merkleRoot_ used to verify the allow list
    constructor(SneakyGenesis sneakyGenesis_, bytes32 merkleRoot_) {
        sneakyGenesis = sneakyGenesis_;
        merkleRoot = merkleRoot_;
    }

    /// @notice Function that sets minting active or inactive
    /// @dev only callable from the contract owner
    function toggleMintActive() external onlyOwner {
        isMintActive = !isMintActive;
    }

    /// @notice Sets the SneakyGenesis contract address
    /// @dev only callable from the contract owner
    function setSneakyGenesis(SneakyGenesis sneakyGenesis_) external onlyOwner {
        sneakyGenesis = sneakyGenesis_;
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
        address[] memory receiver = new address[](1);
        uint256[] memory quantity = new uint256[](1);
        receiver[0] = msg.sender;
        quantity[0] = 1;
        sneakyGenesis.mintTo(receiver, quantity);
    }
}
