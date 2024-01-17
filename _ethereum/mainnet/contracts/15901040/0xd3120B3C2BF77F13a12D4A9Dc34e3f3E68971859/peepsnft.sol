//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract PeepsNFT is ERC721A, Ownable {

    string private baseTokenURI;
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public price = 0.02 ether;
  
    bool public publicSaleIsLive = false;
    bool public presaleIsLive = false;

    mapping(address => bool) public hasMintedWhitelist;
    bytes32 public whitelistMerkleRoot;

    constructor() ERC721A("Peeps NFT", "PEEPS") {
        baseTokenURI = "ipfs://QmcD6FezGzuHxyrKsLkW2mdE3jYVfZVKeh2hbLHkqEsUJi";
    }

    function _verify(bytes32[] memory proof, bytes32 merkleRoot) internal view returns (bool) {
      return MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    function mint(uint256 amount) external payable {
      require(publicSaleIsLive, "Public sale is not active");
      require(totalSupply() + amount <= MAX_SUPPLY, "Exceeded max limit");
      require(amount < 6, "5 limit max per tx");
      require(msg.value >= price * amount, "Insufficient payment");

      _safeMint(msg.sender, amount);
    }

    function whitelistMint(bytes32[] calldata proof) external {
      require(presaleIsLive, "Presale is not active");
      require(!hasMintedWhitelist[msg.sender], "User has already minted");
      require(_verify(proof, whitelistMerkleRoot), "Invalid proof");
      require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeded max limit");

      hasMintedWhitelist[msg.sender] = true;

      _safeMint(msg.sender, 1);
    }

    function ownerMint(uint256 amount) external onlyOwner {
      require(totalSupply() + amount <= MAX_SUPPLY, "Exceeded max supply");

      _safeMint(msg.sender, amount);
    }

    function setWhitelistMerkleRoot(bytes32 root) external onlyOwner {
        whitelistMerkleRoot = root;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setPublicSaleIsLive(bool paused) external onlyOwner {
        publicSaleIsLive = paused;
    }

    function setPresaleIsLive(bool paused) external onlyOwner {
        presaleIsLive = paused;
    }

    function withdrawAll() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, '/', _toString(tokenId), '.json')) : '';
    }
}