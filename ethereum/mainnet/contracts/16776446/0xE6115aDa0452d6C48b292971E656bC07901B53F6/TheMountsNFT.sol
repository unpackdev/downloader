// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721.sol";
import "./IERC721.sol";
// contracts
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./ERC721Enumerable.sol";

contract SeedworldMounts is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string private _tokenBaseURI;
    bool public paused = false;
    bytes32 public root;
    bool public revealed = false;
    mapping(uint256 => string) public _baseURIMapping;
    mapping(address => Whitelist) public whitelists;

    struct Whitelist {
        address wallet;
        string tokenURI;
        bool minted;
    }

    event _setBaseURI(string baseURI);
    event _reveal();
    event _setNewRoot();

    //construct is setting the static image
    constructor(
        bytes32 _root,
        string memory baseURI
    ) ERC721("The Mounts of Seedworld", "TheMounts") {
        root = _root;
        _tokenBaseURI = baseURI;
    }

    /// @param sender - sender of transaction
    /// @param proof - Proof sent from the frontend with the Merkleproof for each user (sender, ids)
    /// @param ids  - Array of ids containing the ids that were raffled with the ipfs ids.
    function safeMint(
        address sender,
        bytes32[] memory proof,
        uint256[] memory ids
    ) public {
        bytes32 leaf = keccak256(abi.encodePacked(sender, ids));
        if (leaf == bytes32(0)) revert("Invalid leaf");
        if (proof.length == 0) revert("Invalid proof");
        if (!isValid(proof, leaf)) revert("Not a part of Allowlist");
        if (paused) revert("The contract is paused");
        if (whitelists[sender].minted)
            revert("You already minted all available mounts");

        whitelists[sender].minted = true;
        for (uint256 i = 0; i < ids.length; i++) {
            _safeMint(sender, ids[i]);
        }
    }

    //Function to check if the wallet is whitelisted through Merkle tree
    function isValid(
        bytes32[] memory proof,
        bytes32 leaf
    ) public view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721) returns (string memory) {
        if (!_exists(tokenId)) {
            revert("ERC721Metadata: URI query for nonexistent token");
        }
        string memory baseURI = _tokenBaseURI;
        if (revealed) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                );
        } else {
            return baseURI;
        }
    }

    function hasUserMinted(address sender) public view returns (bool) {
        return whitelists[sender].minted;
    }

    // Set new base token URI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;

        emit _setBaseURI(baseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    //Function to set the new TokenURI from tokenURI Whitelisted Struct
    function reveal() public onlyOwner {
        revealed = true;
        emit _reveal();
    }

    //function to set a new root in case a user needs to be removed from the whitelist
    function setNewRoot(bytes32 _newroot) public onlyOwner {
        root = _newroot;
        emit _setNewRoot();
    }

    //pause contract
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
}
