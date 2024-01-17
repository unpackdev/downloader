// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MerkleProof.sol";

import "./Token.sol";
import "./Withdrawable.sol";

contract Minter is Ownable, Withdrawable {
    Token public token;

    bytes32 public whitelistRoot;

    uint256 public startTimestamp;

    uint256 public endTimestamp;

    modifier onlyWhitelisted(uint256 tokenId, bytes32[] memory proof) {
        require(MerkleProof.verify(proof, whitelistRoot, keccak256(abi.encode(_msgSender(), tokenId))), "Minter: account mismatch");
        _;
    }

    /* Configuration
     ****************************************************************/

    function schedule(uint256 startTimestamp_, uint256 endTimestamp_) external onlyOwner {
        startTimestamp = startTimestamp_;
        endTimestamp = endTimestamp_;
    }

    function setToken(address token_) external onlyOwner {
        token = Token(token_);
    }

    function setWhitelistRoot(bytes32 whitelistRoot_) external onlyOwner {
        whitelistRoot = whitelistRoot_;
    }

    /* Domain
     ****************************************************************/

    function mint(uint256 tokenId) external onlyOwner {
        token.mint(tokenId, _msgSender());
    }

    function mint(uint256 tokenId, bytes32[] calldata proof) external onlyWhitelisted(tokenId, proof) {
        require(startTimestamp != 0 && block.timestamp >= startTimestamp, "Minting not started");
        require(endTimestamp == 0 || block.timestamp < endTimestamp, "Minting ended");

        token.mint(tokenId, _msgSender());
    }
}
