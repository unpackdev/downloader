// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Random.sol";
import "./MerkleProof.sol";
import "./BitMaps.sol";
import "./Multicall.sol";
import "./ApeGang.sol";
import "./Jaguars.sol";


contract JaguarsDropper is Multicall
{
    using BitMaps for BitMaps.BitMap;
    using Random  for Random.Manifest;

    ApeGang public immutable ape;
    Jaguars public immutable jaguars;
    bytes32 public immutable whitelistRoot;

    BitMaps.BitMap  private __claimedBitMap;
    Random.Manifest private __manifest;

    modifier onlyWhitelisted(bytes32 leaf, bytes32[] memory proof) {
        require(whitelistRoot == bytes32(0) || MerkleProof.verify(proof, whitelistRoot, leaf), "proof is not valid");
        _;
    }

    constructor(ApeGang _ape, Jaguars _jaguars, bytes32 _whitelistRoot)
    {
        ape           = _ape;
        jaguars       = _jaguars;
        whitelistRoot = _whitelistRoot;
        __manifest.setup(5000);
    }

    function isClaimed(uint256 tokenId)
    external view returns (bool)
    {
        return __claimedBitMap.get(tokenId);
    }

    function claim(uint256 tokenId, uint256 count, bytes32[] calldata proof)
    external onlyWhitelisted(keccak256(abi.encodePacked(tokenId, count)), proof)
    {
        require(!__claimedBitMap.get(tokenId), "token already claimed");
        __claimedBitMap.set(tokenId);

        address to   = ape.ownerOf(tokenId);
        bytes32 seed = Random.random();
        for (uint256 i = 0; i < count; ++i)
        {
            jaguars.mint(to, 1 + __manifest.draw(keccak256(abi.encode(seed, i)))); // ids are 1 to 5000
        }
    }
}
