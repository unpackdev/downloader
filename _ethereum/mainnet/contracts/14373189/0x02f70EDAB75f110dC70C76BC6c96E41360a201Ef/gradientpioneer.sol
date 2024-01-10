// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @title Gradient Pioneer token contract
 * @author Gradient
 * @dev ERC721 contract from which users can mint the token directly if they are in the allowlist.
 **/
contract GradientPioneer is ERC721, ERC721Burnable, Ownable {
    string constant baseTokenURI = "https://ipfs.io/ipfs/Qmd7aNcszqsiCGp9S2Sr19bKyBiXDpH2LhgboG9U4GArb5";
    string constant baseContractURI = "https://ipfs.io/ipfs/QmXsPRB1ksfBL1h5x9DSXbosKbtMoNGFnJEueo95hPFXtQ";
    bytes32 constant merkleRoot = 0xe50a8ab4419bf2c58ddac6039dc07c29bf9cbfcfffa0f67ee773b491916d44e7;
    uint256 constant max_supply = 150;

    mapping(address => bool) private allowlistClaimed;
    uint256 private tokenIdCounter;
    bool private sale;

    constructor() ERC721("Gradient Pioneer", "GradientPioneer") {
        tokenIdCounter = 0;
        sale = false;
    }

    /**
    * @dev Mints the token for the caller if they are in the allowlist associated with the merkleRoot
    * @param _merkleProof provides the Merkle proof of caller for verification with Merkle tree
    **/
    function mint(bytes32[] calldata _merkleProof) external {
        require(sale, "Mint not started");
        require(max_supply >= tokenIdCounter, "Sold out");
        require(!allowlistClaimed[msg.sender], "Address already claimed");
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Not in allowlist"
        );

        allowlistClaimed[msg.sender] = true;
        ++tokenIdCounter;
        _mint(msg.sender, tokenIdCounter);
    }

    /**
    * @dev Changes the value of the boolean variable sale
    * @param status is the new value of variable sale
    **/
    function setSale(bool status) external onlyOwner {
        sale = status;
    }

    /**
    * @dev Returns token metadata
    * @param _tokenId is the ID of the token with the associated metadata
    **/
    function tokenURI(uint256 _tokenId) public pure override(ERC721) returns (string memory) {
        return baseTokenURI;
    }

    /**
    * @dev Returns contract metadata
    **/
    function contractURI() public pure returns (string memory) {
        return baseContractURI;
    }

    /**
    * @dev Returns the value of uint256 constant max_supply
    **/
    function totalSupply() public pure returns (uint256) {
        return max_supply;
    }

    /**
    * @dev Prevents wallets from transferring the token to any other wallet but the one with null address
    * @param from is the address that currently owns the token
    * @param to is the address that will receive the token after the transaction
    * @param tokenId is the token ID associated with the token being transferred
    **/
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        require(from == address(0) || to == address(0), "The token can only be burnt and not transferred");
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
