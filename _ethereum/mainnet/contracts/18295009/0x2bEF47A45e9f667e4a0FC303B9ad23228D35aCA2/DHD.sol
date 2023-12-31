// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.19;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract DiamondHandedDeath is ERC721, Ownable {
    bytes32 private root;
    uint256 private _nextTokenId;
    string public _tokenUri;
    bool public sale = false;

    mapping(address => bool) minted;

    event NftMinted(address indexed to, uint256 tokenId);

    constructor(bytes32 _root, string memory _uri) ERC721("DiamondHandedDeath", "DHD") Ownable() {
        root = _root;
        _tokenUri = _uri;
    }

    function mintNft(bytes32[] calldata proof) public {
        require(!minted[_msgSender()], "NFT CLAIMED");
        require(sale, "not on sale");
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_msgSender()))));

        require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
        uint256 tokenId = _nextTokenId++;

        _safeMint(_msgSender(), tokenId);
        minted[_msgSender()] = true;
        emit NftMinted(_msgSender(), tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenUri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return baseURI;
    }

    function updateTokenUri(string memory _uri) public onlyOwner {
        _tokenUri = _uri;
    }

    function toggleSale() public onlyOwner {
        sale = !sale;
    }
}
