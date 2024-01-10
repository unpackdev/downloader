// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/*


   ▄▄▄▄███▄▄▄▄      ▄████████     ███        ▄████████    ▄████████  ▄██████▄  ███    █▄   ▄█        ▄███████▄  
 ▄██▀▀▀███▀▀▀██▄   ███    ███ ▀█████████▄   ███    ███   ███    ███ ███    ███ ███    ███ ███       ██▀     ▄██ 
 ███   ███   ███   ███    █▀     ▀███▀▀██   ███    ███   ███    █▀  ███    ███ ███    ███ ███             ▄███▀ 
 ███   ███   ███  ▄███▄▄▄         ███   ▀   ███    ███   ███        ███    ███ ███    ███ ███        ▀█▀▄███▀▄▄ 
 ███   ███   ███ ▀▀███▀▀▀         ███     ▀███████████ ▀███████████ ███    ███ ███    ███ ███         ▄███▀   ▀ 
 ███   ███   ███   ███    █▄      ███       ███    ███          ███ ███    ███ ███    ███ ███       ▄███▀       
 ███   ███   ███   ███    ███     ███       ███    ███    ▄█    ███ ███    ███ ███    ███ ███▌    ▄ ███▄     ▄█ 
  ▀█   ███   █▀    ██████████    ▄████▀     ███    █▀   ▄████████▀   ▀██████▀  ████████▀  █████▄▄██  ▀████████▀ 
                                                                                          ▀                     
                                                                                                                                                                                                                                                                                                     
*/                                                                                                                                                                                                                                    


import "./ERC721A.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract MetaSoulz is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 3333;

    uint256 public price = 0.066 ether;
    uint256 public maxMint = 2;
    bool public publicSale = false;
    bool public whitelistSale = false;

    mapping(address => uint256) public _whitelistClaimed;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmW8uvY9FgxozpqeGK5WbjXULpdZQUYnBM8dw2yHLk8UTi/"; 
    bytes32 public merkleRoot = 0xe3a5860c77f48f254cc48b899c1d57085f10c1523c53f33fbaccc1abb034efce;

    constructor() ERC721A("MetaSoulz", "META", maxMint) {
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

    //change max mint for wl/public
    function setMaxMint(uint256 _newMaxMint) external onlyOwner {
        maxMint = _newMaxMint;
    }

    //wl only mint
    function whitelistMint(uint256 tokens, bytes32[] calldata merkleProof) external payable {
        require(whitelistSale, "MS: You can not mint right now");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "MS: Please wait to mint on public sale");
        require(_whitelistClaimed[_msgSender()] + tokens <= maxMint, "MS: Max amount of MSs have been minted by this wallet");
        require(tokens <= maxMint, "MS: Exceeded allowed max mint limit");
        require(tokens > 0, "MS: Please mint at least 1 MS");
        require(price * tokens == msg.value, "MS: Not enough ETH");

        _safeMint(_msgSender(), tokens);
        _whitelistClaimed[_msgSender()] += tokens;
    }

    //mint function for public
    function mint(uint256 tokens) external payable {
        require(publicSale, "MS: Public sale has not started");
        require(tokens <= maxMint, "MS: Cannot purchase this many tokens in a transaction");
        require(totalSupply() + tokens <= MAX_TOKENS, "MS: Exceeded supply");
        require(tokens > 0, "MS: Please mint at least 1 MS");
        require(price * tokens == msg.value, "MS: Not enough ETH");
        _safeMint(_msgSender(), tokens);
    }

    // Owner mint has no restrictions. use for giveaways, airdrops, etc
    function ownerMint(address to, uint256 tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "MS: Minting would exceed max supply");
        require(tokens > 0, "MS: Must mint at least one token");
        _safeMint(to, tokens);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
  }
}