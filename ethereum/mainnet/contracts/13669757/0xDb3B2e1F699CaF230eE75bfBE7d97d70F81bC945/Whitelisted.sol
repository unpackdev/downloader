//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Whitelisted is Ownable, ReentrancyGuard {
    bool public isWhitelistActive;
    bytes32 immutable private root;

    constructor(bytes32 _root) {
        root = _root;
    }

    function toggleWhitelist() external onlyOwner {
        isWhitelistActive = !isWhitelistActive;
    }

    function _leaf(address account, uint256 tokenId)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenId, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
