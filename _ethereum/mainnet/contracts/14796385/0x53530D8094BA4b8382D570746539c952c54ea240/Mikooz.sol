// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract Mikooz is Ownable, ERC721A {

    uint256 public constant MAX_SUPPLY = 5678;
    uint256 public constant MAX_SALE_MINTS = 5578;
    uint256 public constant MAX_FOUNDERS_SUPPLY = 100;
    uint256 public privatePrice = 0.04 ether;
    uint256 public publicPrice = 0.06 ether;
    uint256 public maxMint = 3;
    uint256 public mikoozlistMaxMint = 2;
    uint256 public ogMikoozlistMaxMint = 3;
    uint256 public amountMintedFounders;
    uint256 public amountMintedSale;
    mapping(address => uint) private alMinted;
    bool public publicSaleActive = false;
    bool public privateSaleActive = false;
    bytes32 public merkleRoot;
    string public _tokenBaseURI;

    constructor() ERC721A ("Mikooz","MKZ") {}

    function mint(uint256 quantity) external payable {
        require(totalSupply() < MAX_SUPPLY, "We are sold out!");
        require(amountMintedSale < MAX_SALE_MINTS, "We are sold out!");
        require(publicSaleActive, "Public Sale is Paused");
        require(quantity > 0, "Min mint is 1 Mikooz");
        require(quantity <= maxMint, "Transaction exceeds max mint.");
        require( totalSupply() + quantity <= MAX_SUPPLY, "Transaction exceeds max supply.");
        require( publicPrice * quantity == msg.value, "Ether amount is incorrect.");
        amountMintedSale += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mikoozlistMint( uint256 quantity, bytes32[] memory merkleProof, uint isOg) external payable {
        require(verifyProof(_merkleLeaf(msg.sender, isOg),merkleProof),"Data does not match our Allow List.");
        uint256 alMaxMint;
        if (isOg == 0){
            alMaxMint = mikoozlistMaxMint;
        } else {
            alMaxMint = ogMikoozlistMaxMint;
        }
        require(alMinted[msg.sender] + quantity <= alMaxMint,"Exceeds Maximum Allow List Mint Limit.");
        require(totalSupply() < MAX_SUPPLY, "We are sold out!");
        require(amountMintedSale < MAX_SALE_MINTS, "We are sold out!");
        require(privateSaleActive, "Private Sale is Paused");
        require(quantity > 0, "Min mint is 1 Mikooz");
        require(quantity <= alMaxMint, "Transaction exceeds max mint.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Transaction exceeds max supply.");
        require( privatePrice * quantity == msg.value, "Ether amount is incorrect.");
        amountMintedSale += quantity;
        alMinted[msg.sender] += quantity; 
        _safeMint(msg.sender, quantity);
    }
    
    function giftMint(uint256 quantity, address receiver) external onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "We are sold out!");
        require(amountMintedFounders + quantity <= MAX_FOUNDERS_SUPPLY, "Founder Supply has been claimed already.");
        require(quantity > 0, "Min mint is 1 Mikooz.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Transaction exceeds max supply.");
        amountMintedFounders += quantity;
        _safeMint(receiver, quantity);
    }

    function setPublicPrice(uint256 _mintPrice) external onlyOwner {
        publicPrice = _mintPrice;
    }
    
    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }
    
    function setPrivatePrice(uint256 _mintPrice) external onlyOwner {
        privatePrice = _mintPrice;
    }

    function togglePrivateSaleActive() external onlyOwner {
        privateSaleActive = !privateSaleActive;
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _tokenBaseURI;
    }
    
    function _merkleLeaf(address account, uint isOg)
    internal pure
    returns(bytes32)
    {
        return keccak256(abi.encodePacked(account,isOg));
    }

    function verifyProof(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }


    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance can't be zero");
        _withdraw(owner(), address(this).balance);
    }
}