//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract MaskedMicKillers is ERC721A, Ownable {
    using Strings for uint256;

    
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public presalePrice = 0.02 ether;
    uint256 public whitelistPrice = 0.035 ether;
    uint256 public publicPrice = 0.05 ether;

    uint256 public MAX_PER_MINT = 15;
    uint256 public MAX_PER_WHITELIST = 15;

    mapping(address => uint256) public amountPerWhitelist;

    bytes32 public merkleRoot;

    // 0:  Mint is not started
    // 1:  Presale
    // 2:  Whitelist mint
    // 3:  Public
    uint8 public mintStep = 1;
    bool public revealed;
    bool private enabled;

    string public baseTokenURI;
    string public hiddenMetadataUri;

    address public founderAddr = 0x230f315b65CFEA91657d1Eb1fb0C6F3a6fDeBC79;
    address public mapAddr = 0x2AF66D90Efe6B0FD06EA5E2Cab697fA0A293bc18;

    constructor() ERC721A("MaskedMicKillers", "MMK") {
        setHiddenMetadataUri("https://mmk.mypinata.cloud/ipfs/QmcH9fdFRnfJSfwuY8YYpdvH19MAkcEtZb8XveYLJKicJQ");
        _safeMint(founderAddr, 555);
        _safeMint(mapAddr, 10);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function reserveNFTs(uint256 _amount, address _to) public onlyOwner {
        require(totalSupply() + _amount < MAX_SUPPLY, "Not enough NFTs");
        _safeMint(_to, _amount);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : "";
    }

    function mintNFTs(uint256 _count) public payable {
        require(mintStep == 1 || mintStep == 3, "Presale or Public sale is not started!");
        require(totalSupply() + _count < MAX_SUPPLY, "Not enough NFTs!");
        require(_count > 0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        if (mintStep == 3) {
            require(msg.value >= publicPrice * _count, "Not enough ether to purchase NFTs.");
        }

        if (mintStep == 1) {
            require(msg.value >= presalePrice * _count, "Not enough ether to purchase NFTs.");
        }

        _safeMint(msg.sender, _count);
    }

    function whitelistMintNFTs(uint256 _count, bytes32[] calldata _merkleProof) public payable {
        require(mintStep == 2, "Whitelist mint is not started!");
        require(totalSupply() + _count < MAX_SUPPLY, "Not enough NFTs!");
        require(_count + amountPerWhitelist[msg.sender] <= MAX_PER_WHITELIST, "Buy limit exceeded");
        require(_count > 0 && _count <= MAX_PER_MINT, "Cannot mint specified number of NFTs.");
        require(msg.value >= whitelistPrice * _count, "Not enough ether to purchase NFTs.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You are not whitelisted!");

        _safeMint(msg.sender, _count);

        amountPerWhitelist[msg.sender] += _count;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdraw() external onlyOwner {
        require(enabled, "Withdraw is not enabled");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setMaxPerMint(uint8 _number) public onlyOwner {
        MAX_PER_MINT = _number;
    }

    function setMaxPerWhitelist(uint8 _number) public onlyOwner {
        MAX_PER_WHITELIST = _number;
    }

     function setMintStep(uint8 _step) public onlyOwner {
        mintStep = _step;
    }

    function setPrice(uint256 _presale, uint256 _whitelist, uint256 _public) public onlyOwner {
        presalePrice = _presale;
        whitelistPrice = _whitelist;
        publicPrice = _public;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function toggleEnable() external onlyOwner {
      enabled = !enabled;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

}
