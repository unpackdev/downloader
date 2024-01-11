// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Sarutama is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 2222;

    uint256 public price = 0.088 ether;
    uint256 public maxWhitelistMint = 2;
    uint256 public maxPublicMint = 5;
    bool public publicSale = false;
    bool public whitelistSale = false;


    mapping(address => uint256) public _whitelistClaimed;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/Qme4yR978sqmxcxXgj1TAASLSPotZLV1U1PiXFqddy777E/";
    bytes32 public merkleRoot = 0x8bb6d256c7e50e8e92ef2b8cecefee98f701cde8d6065db3ca56150a12504e3e;

    constructor() ERC721A("Sarutama", "SARUTAMA") {
    }

    function toggleWhitelistSale() external onlyOwner {
        whitelistSale = !whitelistSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //change max mint for wl
    function setMaxWhitelistMint(uint256 _newMaxWhitelistMint) external onlyOwner {
        maxWhitelistMint = _newMaxWhitelistMint;
    }

    //change max mint for publix
    function setMaxPublicMint(uint256 _newMaxPublicMint) external onlyOwner {
        maxPublicMint = _newMaxPublicMint;
    }

    //wl only mint
    function whitelistMint(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(whitelistSale, "SARU: You can not mint right now");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "SARU: Please wait to mint on public sale");
        require(_whitelistClaimed[_msgSender()] + tokens <= maxWhitelistMint, "SARU: Cannot mint this many SARUS");
        require(tokens > 0, "SARU: Please mint at least 1 SARU");
        require(price * tokens == msg.value, "SARU: Not enough ETH");

        _safeMint(_msgSender(), tokens);
        _whitelistClaimed[_msgSender()] += tokens;
    }

    //mint function for public
    function mint(uint256 tokens) external payable {
        require(publicSale, "SARU: Public sale has not started");
        require(tokens <= maxPublicMint, "SARU: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "SARU: Exceeded supply");
        require(tokens > 0, "SARU: Please mint at least 1 SARU");
        require(price * tokens == msg.value, "SARU: Not enough ETH");
        _safeMint(_msgSender(), tokens);
    }

    // Owner mint has no restrictions. use for giveaways, airdrops, etc
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "SARU: Minting would exceed max supply");
        require(tokens > 0, "SARU: Must mint at least one token");
        _safeMint(to, tokens);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
  }
}