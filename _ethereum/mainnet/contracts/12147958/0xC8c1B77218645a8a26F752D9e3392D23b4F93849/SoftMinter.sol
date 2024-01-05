// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./console.sol";

interface CanMint {
    function mint(address to, uint256 tokenId) external;
}

contract SoftMinter is Ownable {
    // Mapping from address to bool, if egg was already claimed
    // The hash is about the userId and the nftIds array
    mapping(address => mapping(bytes32 => bool)) public registeredHashes;
    mapping(uint256 => bool) public alreadyMinted;

    CanMint private _nftContract;

    constructor(CanMint nftContract) public {
        _nftContract = nftContract;
    }

    function mint(
        address to,
        uint256[] memory ids,
        uint256 indexToMint
    ) public {
        require(
            registeredHashes[to][keccak256(abi.encode(to, ids))],
            "Hash not registered"
        );
        require(!alreadyMinted[ids[indexToMint]], "Already minted");
        if (registeredHashes[to][keccak256(abi.encode(to, ids))]) {
            alreadyMinted[ids[indexToMint]] = true;
            _nftContract.mint(to, ids[indexToMint]);
        }
    }

    //adding hash
    function addHash(address to, bytes32 dataHash) public onlyOwner {
        require(!registeredHashes[to][dataHash], "Hash already registered");
        registeredHashes[to][dataHash] = true;
    }
}
