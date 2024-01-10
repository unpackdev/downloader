// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// @author mHm's Developper
// hello@metahumannft.io

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract Metahuman is Ownable, ERC721A {

    using Strings for uint;

    uint public constant maxSupply = 10000;

    uint public presalePrice = 0.06 ether;
    uint public publicPrice = 0.07 ether;

    string public baseURI;

    bool public openPreSale = false;
    bool public openPublicSale = false;

    bytes32 public merkleRoot;

    address private holder;

    constructor(
        string memory _baseURI,
        address _holder,
        bytes32 _root
    ) ERC721A("Metahuman", "MHM") {
        baseURI = _baseURI;
        merkleRoot = _root;
        holder = _holder;
    }

    //Security
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "wrong caller");
        _;
    }

    //Airdrop
    function adminMint(address to, uint qty) public onlyOwner {
        require(qty > 0, "minimum 1 token");
        require(totalSupply() + qty <= maxSupply, "SOLD OUT!");
        _safeMint(to, qty);
    }

    //Update Whitelist
    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    //Presale settings
    function changePresalePrice(uint _newPresalePrice) external onlyOwner {
        presalePrice = _newPresalePrice;
    }

    function setPreSale(bool _closePreSale) external onlyOwner {
        openPreSale = _closePreSale;
    }

    function presaleMint(bytes32[] calldata _merkleProof, uint qty
    ) external payable callerIsUser {
        require(openPreSale, "presale not started yet");
        require(presalePrice * qty == msg.value, "please add more found on your wallet");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "you are not whitelisted");
        require(totalSupply() + qty <= maxSupply, "SOLD OUT! buy on Opensea!");
        require(qty <= 6, "no more than 6 at once!");
        _safeMint(msg.sender, qty);
    }

    //Publicsale settings
    function changePublicPrice(uint _newPublicPrice) external onlyOwner {
        publicPrice = _newPublicPrice;
    }

    function setPublicSale(bool _closePublicSale) external onlyOwner {
        openPublicSale = _closePublicSale;
    }

    function publicMint(uint qty) external payable callerIsUser{
        require(openPublicSale, "be patient! public sale is coming soon");
        require(qty <= 6, "no more than 6 at once!");
        require(totalSupply() + qty <= maxSupply, "SOLD OUT! buy on Opensea!");
        require(publicPrice * qty == msg.value, "please add more found on your wallet");
        _safeMint(msg.sender, qty);
    }

    //URI settings
    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    //Withdraw
    function cashOut() external onlyOwner {
		payable(holder).transfer(address(this).balance);
	}
}