// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./IWhitelist.sol";

contract Whitelist is IWhitelist, Ownable {
    bytes32 public whitelistedMerkelRoot;

    function setWhitelistedMerkleRoot(bytes32 _whitelistedRoot)
        external
        override
        onlyOwner
    {
        require(_whitelistedRoot != bytes32(0), "SipherNFTSale: invalid root");
        whitelistedMerkelRoot = _whitelistedRoot;
        emit SetWhitelistedMerkleRoot(_whitelistedRoot);
    }

    function isWhitelistedAddress(address buyer, uint32 privateCap, uint32 freeMintCap , bytes32[] memory proofs)
        public
        view
        override
        returns (bool)
    {
        require(whitelistedMerkelRoot != bytes32(0));
        bytes32 computedHash = keccak256(abi.encode(buyer, privateCap, freeMintCap));
        for (uint256 i = 0; i < proofs.length; i++) {
            bytes32 proofElement = proofs[i];
            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash == whitelistedMerkelRoot;
    }


}
