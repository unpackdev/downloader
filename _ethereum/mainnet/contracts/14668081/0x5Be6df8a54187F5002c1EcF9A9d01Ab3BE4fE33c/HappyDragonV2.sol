// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721a.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract HappyDragon is ERC721A, Ownable {
    
    uint constant public MAX_SUPPLY = 10000;
    uint public preserved = 100;
    uint public price = 0.1 ether;
    uint public supplyCurrentRound;
    uint public startTimeCurrentRound;
    uint public endTimeCurrentRound;
    string public baseURI =  "ipfs://QmSiT8NrHZ2dYNR841vvNNF7xA7oSn3ALHHMjtp4iFsSQb/";
    bytes32 public whiteListRoot;
    mapping(address=>bool) claimedAddress;
    
    constructor() public ERC721A("Happy Dragon", "HAPPY"){
        
    }
     
    function mint(uint256 quantity) public payable{
        require(quantity>0, "Quantity must be greater than 0");
        require((totalSupply() + quantity) <= supplyCurrentRound && (totalSupply() + quantity) <= (MAX_SUPPLY - preserved), "No enough dragons left");
        require(startTimeCurrentRound < block.timestamp && endTimeCurrentRound > block.timestamp, "The sale is invalid");
        require(msg.value >= price * quantity, "Insufficient payment");

        _safeMint(msg.sender, quantity);
    }

    function checkWhiteList(bytes32[] calldata _merkleProof) public view returns (bool){
        require(!claimedAddress[msg.sender], "You have claimed the dragon");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whiteListRoot, leaf), "Incorrect proof");
        return true;
    }

    function claim(bytes32[] calldata _merkleProof) public{
        checkWhiteList(_merkleProof);
        require((totalSupply() + 1) <= supplyCurrentRound, "No enough dragons left");
        _safeMint(msg.sender, 1);
        preserved = preserved - 1;
        claimedAddress[msg.sender] = true;
    }

    function setCurrentRound(uint _supplyCurrentRound, uint _startTimeCurrentRound, uint _endTimeCurrentRound) public onlyOwner{
        require(_supplyCurrentRound <= MAX_SUPPLY, "Invalid supply");
        supplyCurrentRound = _supplyCurrentRound;
        startTimeCurrentRound = _startTimeCurrentRound;
        endTimeCurrentRound = _endTimeCurrentRound;
    }

    function withdraw() public onlyOwner{
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function setPrice(uint256 _price) onlyOwner public{
        price = _price;
    }
    
    function setBaseURI(string memory _baseURI) onlyOwner public{
        baseURI = _baseURI;
    }

    function setWhiteList(bytes32 _whiteListRoot) onlyOwner public{
        whiteListRoot = _whiteListRoot;
    }

    function _baseURI() override internal view returns (string memory) {
        return baseURI;
    }
    
}