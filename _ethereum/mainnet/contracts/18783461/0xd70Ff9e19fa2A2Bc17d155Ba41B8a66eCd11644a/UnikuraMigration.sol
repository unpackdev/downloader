// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IUnikuraCollectibles.sol";
import "./UnikuraErrors.sol";
import "./IUnikuraMigration.sol";

contract UnikuraMigration is IUnikuraMigration, Ownable {
    IUnikuraCollectibles public collection;
    bytes32 public merkleRoot = "";
    address public tokenReceiver;
    mapping(address => bool) public minted;

    constructor(address _tokenReceiver) {
        tokenReceiver = _tokenReceiver;
    }

    function setCollection(address token) external override onlyOwner {
        if (token == address(0)) {
            revert UnikuraErrors.ZeroAddress();
        }
        emit CollectionChanged(address(collection), token);
        collection = IUnikuraCollectibles(token);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external override onlyOwner {
        emit MerkleRootChanged(merkleRoot, _merkleRoot);
        merkleRoot = _merkleRoot;
    }

    function migrate(address oldToken, uint256 tokenId, bytes32[] memory proof) external override {
        if (minted[oldToken]) {
            revert UnikuraErrors.TokenMinted(1);
        }

        bytes32 leaf = keccak256(abi.encodePacked(oldToken));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) {
            revert UnikuraErrors.InvalidProof(oldToken);
        }

        IERC721(oldToken).safeTransferFrom(msg.sender, tokenReceiver, 1);
        minted[oldToken] = true;

        collection.mint(msg.sender, tokenId);

        emit Migrate(msg.sender, oldToken, tokenId);
    }
}
