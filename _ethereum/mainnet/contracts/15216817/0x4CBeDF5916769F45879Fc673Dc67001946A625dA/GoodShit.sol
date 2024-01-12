// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract GoodShit is ERC721A, Ownable, ReentrancyGuard  {
   
    using Strings for uint;

    enum State {
        Before,
        ShitlistSale,
        PoopsSale,
        SoldOut
    }

    State public sellingState;

    string public baseURI = "ipfs://QmWTVd5kqkM6RCZDkU8b9kbjnDVtpaHczjxnGZjaZ9q6wr/";
    
    uint private constant MAX_POOP_MINTS = 5;
    uint private constant MAX_SHIT_SUPPLY = 5555;
    uint public poopsMintRate = 0.015 ether;
    uint private price = 0 ether;

    mapping (address => bool) public freeShitMinted;

    bytes32 public merkleRoot;

    constructor(bytes32 _merkleRoot) ERC721A("GoodShit", "GDSHT") {
        merkleRoot = _merkleRoot;
    }

    function shitlistMint(uint256 quantity,bytes32[] memory proof) external payable {

        require(sellingState == State.ShitlistSale, "Shitlist sale not started yet or has ended!");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "You are not in the shitlist you shithead!");
        require(msg.sender == tx.origin, "Contract minting not allowed you shithead.");
        require(quantity + _numberMinted(msg.sender) <= MAX_POOP_MINTS, "Exceeded the mint limit you greedy shit!");
        require(totalSupply() + quantity <= MAX_SHIT_SUPPLY, "NOT ENOUGH SHITS LEFT YOOO!");

        if(freeShitMinted[msg.sender])
        { 
            price = quantity * poopsMintRate;
        }
        else
        {
            freeShitMinted[msg.sender] = true;
            price = (quantity-1) * poopsMintRate;
        }

        require(msg.value >= price, "Not enough ether sent you poor shit!");
        _safeMint(msg.sender, quantity);

    }

    function poopsMint(uint256 quantity) external payable {

        require(sellingState == State.PoopsSale, "Shit sale not started yet or has ended!");
        require(msg.sender == tx.origin, "Contract minting not allowed you shithead.");
        require(quantity + _numberMinted(msg.sender) <= MAX_POOP_MINTS, "Exceeded the mint limit you greedy shit!");
        require(totalSupply() + quantity <= MAX_SHIT_SUPPLY, "NOT ENOUGH SHITS LEFT YOOO!");

        if(freeShitMinted[msg.sender])
        { 
            price = quantity * poopsMintRate;
        }
        else
        {
            freeShitMinted[msg.sender] = true;
            price = (quantity-1) * poopsMintRate;
        }

        require(msg.value >= price, "Not enough ether sent you poor shit!");
        _safeMint(msg.sender, quantity);
            
        
    }

    function giveawayMint(address _to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SHIT_SUPPLY, "Not enough shits left!");
        _safeMint(_to, quantity);
    }

    function setStep(uint _state) external onlyOwner {
        sellingState = State(_state);
    }

    function setPoopsSaleMintRate(uint256 _mintRate) public onlyOwner {
        poopsMintRate = _mintRate;
    }

    function withdrawShitCoins() external onlyOwner {
        require(address(this).balance > 0,"You do not have enough balance!");
        payable(owner()).transfer(address(this).balance);
    }

    function changeBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();
        
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";

    }
        
    function updateMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

}