//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";

contract PTBPFP is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;

    string public contractURI;
    address public immutable baton;
    address public signer;

    mapping(uint256 => mapping(address => bool)) public claimed;
    mapping(uint256 => string) private uris;

    constructor(
        string memory name_,
        string memory symbol_,
        address baton_
    ) ERC721(name_, symbol_) Ownable() {
        baton = baton_;
    }

    function claim(
        uint256 batonId,
        string memory uri,
        bytes memory signature
    ) public {
        // we should prove the existence of event log "Donate()"
        // but it is not able to implement it with current primitives.
        bytes32 h = keccak256(abi.encodePacked(batonId, msg.sender, uri));
        require(h.recover(signature) == signer, "Invalid signature");
        require(IERC721(baton).ownerOf(batonId) == msg.sender, "Owner can mint a pfp");
        require(!claimed[batonId][msg.sender], "Already claimed");
        require(bytes(uri).length != 0, "Empty Metadata");
        claimed[batonId][msg.sender] = true;
        uint256 tokenId = totalSupply();
        uris[tokenId] = uri;
        _safeMint(msg.sender, tokenId);
    }

    function setSigner(address signer_) public onlyOwner {
        signer = signer_;
    }

    function updateContractURI(string memory uri_) public onlyOwner {
        contractURI = uri_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return uris[tokenId];
    }
}
