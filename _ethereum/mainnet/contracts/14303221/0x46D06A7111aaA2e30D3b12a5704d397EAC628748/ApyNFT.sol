// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

// File: contracts/APYNFTs.sol

/**
 * @title APYNFTs contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract ApyNFT is ERC721Enumerable, Ownable {
    bytes32 public immutable PROVENANCE;
    uint256 public immutable MAX_SUPPLY;
    string public baseURI;
    mapping(address => bool) public hasMinted;
    bytes32 public root;

    constructor(
        string memory name,
        string memory symbol,
        bytes32 provenance,
        uint256 maxSupply,
        bytes32 newRoot
    ) ERC721(name, symbol) {
        PROVENANCE = provenance;
        MAX_SUPPLY = maxSupply;
        root = newRoot;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setRoot(bytes32 newRoot) public onlyOwner {
        root = newRoot;
    }

    function verify(bytes32[] memory proof, address to)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, keccak256(abi.encodePacked(to)));
    }

    function mint(bytes32[] memory proof, address to) public {
        require(totalSupply() <= MAX_SUPPLY, "max supply reached");
        require(!hasMinted[to], "address has already minted");
        require(verify(proof, to), "address is not whitelisted");
        hasMinted[to] = true;
        _safeMint(to, totalSupply());
    }

    function reserve(uint256 mintAmt) public onlyOwner {
        require(
            totalSupply() + mintAmt <= MAX_SUPPLY,
            "mint amount exceeds max supply"
        );
        for (uint256 i = 0; i < mintAmt; i++) {
            _safeMint(owner(), totalSupply());
        }
    }
}
