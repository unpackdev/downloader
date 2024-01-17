// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./MerkleProof.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./INFT.sol";

contract FWCQ2022 is INFT, ERC721, ReentrancyGuard, ERC721Enumerable, Ownable {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string public baseURI;
    string public defaultBoxURI =
        "ipfs://bafybeicufxqii7bgbu2utlnnfnj3ran63kdxys7ae3olndf46jigwx42ie";

    uint256 public immutable collectionSize = 2000;
    bytes32 public merkleRoot;

    mapping(address => bool) public mintedUsers;

    function tokenURI(uint256 tokenId)
        public
        view
        override(INFT, ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (bytes(baseURI).length > 0) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                );
        } else {
            return defaultBoxURI;
        }
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    // free mint
    function freeMint(bytes32[] calldata merkleProof) external override(INFT) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "Valid proof required.");

        require(!mintedUsers[msg.sender], "already minted");

        require(totalSupply() <= collectionSize, "reached max supply");

        mintedUsers[msg.sender] = true;
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(_msgSender(), tokenId);
        emit Minted(_msgSender(), tokenId, block.timestamp);
    }

    ///////////////////////////////////////////////////////////////////////
    /* ================ OWNER ACTIONS ================ */
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory newBaseURI) public override onlyOwner {
        baseURI = newBaseURI;
    }

    function setDefaultBaseURI(string memory newDefaultBoxURI)
        public
        onlyOwner
    {
        defaultBoxURI = newDefaultBoxURI;
    }

    ///////////////////////////////////////////////////////////////////////
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////////

    constructor() ERC721("FIFA WORLD CUP Qatar2022", "FWCQ") {}
}
