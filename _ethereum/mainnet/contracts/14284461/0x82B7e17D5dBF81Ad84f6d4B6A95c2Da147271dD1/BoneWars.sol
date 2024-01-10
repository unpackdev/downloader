// SPDX-License-Identifier: UNLICENSED
//
// 888888b.                                   888       888                           
// 888  "88b                                  888   o   888                           
// 888  .88P                                  888  d8b  888                           
// 8888888K.   .d88b.  88888b.   .d88b.       888 d888b 888  8888b.  888d888 .d8888b  
// 888  "Y88b d88""88b 888 "88b d8P  Y8b      888d88888b888     "88b 888P"   88K      
// 888    888 888  888 888  888 88888888      88888P Y88888 .d888888 888     "Y8888b. 
// 888   d88P Y88..88P 888  888 Y8b.          8888P   Y8888 888  888 888          X88 
// 8888888P"   "Y88P"  888  888  "Y8888       888P     Y888 "Y888888 888      88888P' 
// 
// https://bonewars.io
// https://discord.gg/AHKcHJGBt8
// https://twitter.com/bone_wars

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Context.sol";
import "./MerkleProof.sol";

contract BoneWars is ERC721, Ownable {

    using Strings for uint256;
    using MerkleProof for bytes32[];

    string public baseURI;
    string public baseExtension = ".json";

    uint256 public currentPrice = 0.03 ether; // Public 0.035 ether
    uint256 public maxMintSupply = 3333;
    uint256 public totalSupply = 0;
    uint256 public maxWhitelistMintPerWallet = 4;
    uint256 public maxMintPerTxn = 10;

    bool public publicPaused = true;
    bool public whitelistPaused = true;
    bool public claimPaused = false;
    bool public revealed = false;

    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) public whitelistMintPerWallet;
    mapping(address => uint256) public claimLimitPerWallet;
    mapping(address => uint256) public claimedPerWallet;

    constructor()
    ERC721("Bone Wars", "BW") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) public payable {
        require(!publicPaused, "mint: public sale not active");
        require(quantity > 0, "mint: minimum 1");
        require(quantity <= maxMintPerTxn, "mint: exceeded maximum quantity per txn");
        require(totalSupply + quantity <= maxMintSupply, "mint: would exceed max supply");
        require(msg.value >= currentPrice * quantity, "mint: ether sent is not correct");

        for (uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
        }
    }

    function mintWhitelist(
        bytes32[] calldata proof,
        uint256 quantity
    ) public payable {
        require(proof.verify(whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "mint: not on whitelist");
        require(!whitelistPaused, "mint: whitelist sale not active");
        require(whitelistMintPerWallet[msg.sender] + quantity <= maxWhitelistMintPerWallet, "mint: exceeds maximum quanity per whitelist");
        require(quantity > 0, "mint: minimum 1");
        require(quantity <= maxWhitelistMintPerWallet, "mint: exceeded maximum quantity per txn for whitelist");
        require(totalSupply + quantity <= maxMintSupply, "mint: would exceed max supply");
        require(msg.value >= currentPrice * quantity, "mint: ether sent is not correct");

        for (uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            whitelistMintPerWallet[msg.sender] += 1;
            totalSupply += 1;
        }
    }

    function addClaim(address _address, uint256 quantity) public onlyOwner {
        claimLimitPerWallet[_address] = quantity;
    }

    function removeClaim(address _address) public onlyOwner {
        delete claimLimitPerWallet[_address];
    }

    function getClaimLimit(address _address) public view returns (uint256) {
        return claimLimitPerWallet[_address];
    }

    function getClaimed(address _address) public view returns (uint256) {
        return claimedPerWallet[_address];
    }

    function claim(
        uint256 quantity
    ) public {
        require(!claimPaused, "mint: claim not active");
        require(claimedPerWallet[msg.sender] + quantity <= claimLimitPerWallet[msg.sender], "mint: exceeds maximum claim quantity for this wallet");
        require(quantity > 0, "mint: minimum 1");
        require(quantity <= maxWhitelistMintPerWallet, "mint: exceeded maximum quantity per txn for whitelist");
        require(totalSupply + quantity <= maxMintSupply, "mint: would exceed max supply");
        
        for (uint i = 0; i < quantity; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            claimedPerWallet[msg.sender] += 1;
            totalSupply += 1;
        }
    }

    function gift(
        address _wallet,
        uint256 quantity
    ) public onlyOwner {
        require(quantity > 0, "gift: minimum 1");
        require(totalSupply + quantity <= maxMintSupply, "gift: would exceed max supply");

        for(uint256 i; i < quantity; i++){
            _safeMint(_wallet, totalSupply + 1);
            totalSupply += 1;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        if (revealed) {
            return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
        } else {
            return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, "preview", baseExtension))
                : "";
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        currentPrice = _newPrice;
    }

    function setMaxMintPerTxn(uint256 _newMaxMintPerTxn) public onlyOwner {
        maxMintPerTxn = _newMaxMintPerTxn;
    }

    function setMaxMintPerWhitelist(uint256 _newMaxMintPerWhitelist) public onlyOwner {
        maxWhitelistMintPerWallet = _newMaxMintPerWhitelist;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setWhitelistPaused(bool _state) public onlyOwner {
        whitelistPaused = _state;
    }

    function setPublicPaused(bool _state) public onlyOwner {
        publicPaused = _state;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setTotalSupply(uint256 newSupply) public onlyOwner {
        maxMintSupply = newSupply;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTo(address _to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}
