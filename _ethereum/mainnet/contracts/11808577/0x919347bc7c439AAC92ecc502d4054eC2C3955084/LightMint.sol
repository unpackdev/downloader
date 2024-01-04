// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.11;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IOVRLand.sol";

contract LightMint is Ownable {
    address public ovrLand;
    bytes32 public merkleRoot;

    uint256 private mappingVersion;
    mapping(bytes32 => bool) private claimedMap;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    function setOVRLand(address ovrLand_) external onlyOwner {
        ovrLand = ovrLand_;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
        mappingVersion++;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        bytes32 key = keccak256(abi.encodePacked(mappingVersion, index));
        return claimedMap[key];
    }

    function _setClaimed(uint256 index) private {
        bytes32 key = keccak256(abi.encodePacked(mappingVersion, index));
        claimedMap[key] = true;
    }

    function claim(
        uint256 index,
        address account,
        uint256 OVRLandID,
        string calldata uri,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, OVRLandID, uri));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IOVRLand(ovrLand).mintLand(account, OVRLandID), 'MerkleDistributor: Mint failed.');
        IOVRLand(ovrLand).setOVRLandURI(OVRLandID, uri);
    }
}
